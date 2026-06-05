#!/usr/bin/env bash
# Deploys the VICTIM AWS infrastructure the attack will target:
#   - a "loot" S3 bucket with fake sensitive data (private by default)
#   - a dedicated CloudTrail trail the debug-tools will later disable
# No attack actions here. Safe to run during lab setup.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE="$DIR/.infra-state"
: > "$STATE"

ACCT=$(aws sts get-caller-identity --query Account --output text)
REGION="${AWS_REGION:-us-east-1}"
LOOT="acme-customer-data-${ACCT}"
TRAIL="org-management-trail"
TLOGS="org-cloudtrail-logs-${ACCT}"

echo "[infra/aws] account=$ACCT region=$REGION"

# --- Loot bucket (private baseline; the attack will make it public) ---
echo "[infra/aws] creating loot bucket s3://$LOOT ..."
aws s3api create-bucket --bucket "$LOOT" --region "$REGION" >/dev/null 2>&1 || true
aws s3api put-public-access-block --bucket "$LOOT" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true >/dev/null
printf 'db_password=Sup3rS3cret!\napi_key=AKIA-FAKE-EXAMPLE-KEY\ncustomers=12873\n' \
  | aws s3 cp - "s3://$LOOT/secrets/customer-db.txt" >/dev/null
# Fake customer PII (obviously synthetic) — the data the debug-tools exfiltrates.
printf 'id,name,email,ssn,credit_card\n1,Ada Lovelace,ada@example.com,000-00-0001,4111111111111111\n2,Alan Turing,alan@example.com,000-00-0002,4111111111111112\n3,Grace Hopper,grace@example.com,000-00-0003,4111111111111113\n' \
  | aws s3 cp - "s3://$LOOT/pii/customers.csv" >/dev/null
echo "LOOT_BUCKET=$LOOT" >> "$STATE"

# --- Dedicated CloudTrail trail (debug-tools will StopLogging on this one) ---
echo "[infra/aws] creating trail log bucket s3://$TLOGS ..."
aws s3api create-bucket --bucket "$TLOGS" --region "$REGION" >/dev/null 2>&1 || true
POLICY=$(cat <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {"Sid":"AWSCloudTrailAclCheck","Effect":"Allow","Principal":{"Service":"cloudtrail.amazonaws.com"},
     "Action":"s3:GetBucketAcl","Resource":"arn:aws:s3:::$TLOGS"},
    {"Sid":"AWSCloudTrailWrite","Effect":"Allow","Principal":{"Service":"cloudtrail.amazonaws.com"},
     "Action":"s3:PutObject","Resource":"arn:aws:s3:::$TLOGS/AWSLogs/$ACCT/*",
     "Condition":{"StringEquals":{"s3:x-amz-acl":"bucket-owner-full-control"}}}
  ]
}
JSON
)
aws s3api put-bucket-policy --bucket "$TLOGS" --policy "$POLICY" >/dev/null
echo "TRAIL_LOG_BUCKET=$TLOGS" >> "$STATE"

echo "[infra/aws] creating + starting trail $TRAIL ..."
aws cloudtrail create-trail --name "$TRAIL" --s3-bucket-name "$TLOGS" >/dev/null 2>&1 || true
aws cloudtrail start-logging --name "$TRAIL" >/dev/null
# Enable S3 object-level (data) events for the loot bucket so the debug-tools's
# GetObject exfil is captured in CloudTrail — management events alone miss it.
aws cloudtrail put-event-selectors --trail-name "$TRAIL" \
  --event-selectors "[{\"ReadWriteType\":\"All\",\"IncludeManagementEvents\":true,\"DataResources\":[{\"Type\":\"AWS::S3::Object\",\"Values\":[\"arn:aws:s3:::$LOOT/\"]}]}]" >/dev/null 2>&1 || true
echo "TRAIL=$TRAIL" >> "$STATE"

# --- Limited "victim app" IAM user (the credentials the app is misconfigured ---
# --- with). Deliberately over-permissioned for everything EXCEPT reading the   ---
# --- loot directly: NO s3:GetObject is granted (implicit deny). The debug-tools   ---
# --- abuses s3:PutBucketPolicy to make the bucket public, then reads it — the  ---
# --- realistic "access denied -> escalate -> succeed" arc.                     ---
VICTIM_USER="orders-api-svc-${ACCT}"
echo "[infra/aws] creating limited IAM user $VICTIM_USER ..."
aws iam create-user --user-name "$VICTIM_USER" >/dev/null 2>&1 || true
aws iam put-user-policy --user-name "$VICTIM_USER" --policy-name orders-api-svc-policy --policy-document "{
  \"Version\":\"2012-10-17\",
  \"Statement\":[
    {\"Sid\":\"Recon\",\"Effect\":\"Allow\",\"Action\":[\"sts:GetCallerIdentity\",\"iam:ListUsers\",\"iam:ListRoles\",\"s3:ListAllMyBuckets\",\"s3:ListBucket\",\"s3:GetBucketPolicy\",\"s3:GetBucketPublicAccessBlock\"],\"Resource\":\"*\"},
    {\"Sid\":\"AbuseBucketPerms\",\"Effect\":\"Allow\",\"Action\":[\"s3:PutBucketPolicy\",\"s3:PutBucketPublicAccessBlock\"],\"Resource\":[\"arn:aws:s3:::$LOOT\",\"arn:aws:s3:::$LOOT/*\"]},
    {\"Sid\":\"CloudPersistence\",\"Effect\":\"Allow\",\"Action\":[\"iam:CreateAccessKey\",\"iam:ListAccessKeys\"],\"Resource\":\"arn:aws:iam::${ACCT}:user/$VICTIM_USER\"},
    {\"Sid\":\"DefenseEvasion\",\"Effect\":\"Allow\",\"Action\":[\"cloudtrail:StopLogging\",\"cloudtrail:DescribeTrails\"],\"Resource\":\"*\"}
  ]
}" >/dev/null
echo "VICTIM_USER=$VICTIM_USER" >> "$STATE"

# Mint the access key the app will carry.
KEYJSON=$(aws iam create-access-key --user-name "$VICTIM_USER" 2>/dev/null)
VICTIM_AK=$(echo "$KEYJSON" | jq -r '.AccessKey.AccessKeyId')
VICTIM_SK=$(echo "$KEYJSON" | jq -r '.AccessKey.SecretAccessKey')
echo "VICTIM_AK=$VICTIM_AK" >> "$STATE"
echo "VICTIM_SK=$VICTIM_SK" >> "$STATE"

# IAM is eventually consistent — a brand-new access key takes a few seconds to
# become usable. Wait until it authenticates before anything depends on it, so
# the attack's later AccessDenied is the INTENDED authorization failure (no
# s3:GetObject) and not a transient "key not active yet".
echo "[infra/aws] waiting for the victim key to propagate ..."
for _ in $(seq 1 30); do
  if AWS_ACCESS_KEY_ID="$VICTIM_AK" AWS_SECRET_ACCESS_KEY="$VICTIM_SK" \
     aws sts get-caller-identity >/dev/null 2>&1; then
    echo "[infra/aws] victim key is live."
    break
  fi
  sleep 3
done

echo "[infra/aws] done. State recorded in $STATE:"
cat "$STATE"
