#!/usr/bin/env bash
# Deploys the VICTIM AWS infrastructure the attack will target:
#   - a "loot" S3 bucket with fake sensitive data (private by default)
#   - a dedicated CloudTrail trail the attacker will later disable
# No attack actions here. Safe to run during lab setup.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE="$DIR/.infra-state"
: > "$STATE"

ACCT=$(aws sts get-caller-identity --query Account --output text)
REGION="${AWS_REGION:-us-east-1}"
LOOT="attack-demo-loot-${ACCT}"
TRAIL="attack-demo-trail"
TLOGS="attack-demo-trail-logs-${ACCT}"

echo "[infra/aws] account=$ACCT region=$REGION"

# --- Loot bucket (private baseline; the attack will make it public) ---
echo "[infra/aws] creating loot bucket s3://$LOOT ..."
aws s3api create-bucket --bucket "$LOOT" --region "$REGION" >/dev/null 2>&1 || true
aws s3api put-public-access-block --bucket "$LOOT" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true >/dev/null
printf 'db_password=Sup3rS3cret!\napi_key=AKIA-FAKE-EXAMPLE-KEY\ncustomers=12873\n' \
  | aws s3 cp - "s3://$LOOT/secrets/customer-db.txt" >/dev/null
# Fake customer PII (obviously synthetic) — the data the attacker exfiltrates.
printf 'id,name,email,ssn,credit_card\n1,Ada Lovelace,ada@example.com,000-00-0001,4111111111111111\n2,Alan Turing,alan@example.com,000-00-0002,4111111111111112\n3,Grace Hopper,grace@example.com,000-00-0003,4111111111111113\n' \
  | aws s3 cp - "s3://$LOOT/pii/customers.csv" >/dev/null
echo "LOOT_BUCKET=$LOOT" >> "$STATE"

# --- Dedicated CloudTrail trail (attacker will StopLogging on this one) ---
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
# Enable S3 object-level (data) events for the loot bucket so the attacker's
# GetObject exfil is captured in CloudTrail — management events alone miss it.
aws cloudtrail put-event-selectors --trail-name "$TRAIL" \
  --event-selectors "[{\"ReadWriteType\":\"All\",\"IncludeManagementEvents\":true,\"DataResources\":[{\"Type\":\"AWS::S3::Object\",\"Values\":[\"arn:aws:s3:::$LOOT/\"]}]}]" >/dev/null 2>&1 || true
echo "TRAIL=$TRAIL" >> "$STATE"

echo "[infra/aws] done. State recorded in $STATE:"
cat "$STATE"
