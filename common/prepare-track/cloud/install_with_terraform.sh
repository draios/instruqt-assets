#!/usr/bin/env bash
##
# Deploy the Sysdig Secure for Cloud infra for different cloud vendors
#
# Usage:
#   install_with_terraform.sh $PROVIDER $SYSDIG_SECURE_API_TOKEN $SECURE_API_ENDPOINT $CLOUD_REGION $CLOUD_ACCOUNT_ID
##

apt update && apt install -y less

# logs
OUTPUT=/opt/sysdig/cloud/terraform_install.out
mkdir -p /opt/sysdig/cloud/
touch $OUTPUT

PROVIDER=$1
SYSDIG_SECURE_API_TOKEN=$2
SECURE_API_ENDPOINT=$3
CLOUD_REGION=$4
CLOUD_ACCOUNT_ID=$5
RANDOM_ID=$(cat /opt/sysdig/random_string_OK)

cd /root/prepare-track/cloud

if [ "$PROVIDER" == "aws" ]
then
    cd aws

    bucket_name="audit-$RANDOM_ID)"
    trail_name="trail-$bucket_name"

    # Create an S3 bucket
    aws s3api create-bucket --bucket "$bucket_name" --region us-east-1 | jq '.'

    # Generate a bucket policy JSON file
    cat <<EOF > bucket-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck20150319",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::$bucket_name"
        },
        {
            "Sid": "AWSCloudTrailWrite20150319",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::$bucket_name/AWSLogs/${CLOUD_ACCOUNT_ID}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
EOF

    # Apply the bucket policy
    aws s3api put-bucket-policy --bucket "$bucket_name" --policy file://bucket-policy.json  | jq '.'

    # Create a CloudTrail trail
    aws cloudtrail create-trail --name "$trail_name" --s3-bucket-name "$bucket_name"  | jq '.'

    # Start the trail
    aws cloudtrail start-logging --name "$trail_name" | jq '.'

    API_ENDPOINT="/api/secure/onboarding/v3/environments/AWS/installActions/Terraform"
    FEATURES=""
    # FEATURES=${FEATURES}"&feature=FEATURE_SECURE_IDENTITY_ENTITLEMENT"
    FEATURES=${FEATURES}"&feature=FEATURE_SECURE_THREAT_DETECTION"
    FEATURES=${FEATURES}"&feature=FEATURE_SECURE_CONFIG_POSTURE"
    PARAMETERS="?accountType=single&region=us-east-1"
    PARAMETERS=${PARAMETERS}${FEATURES}

    curl -s -k -X GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${SYSDIG_SECURE_API_TOKEN}" \
        "${SECURE_API_ENDPOINT}${API_ENDPOINT}${PARAMETERS}" > api_response.json

    rm cloud-connector-aws.tf

    cat api_response.json | jq -r .installAction > main.tf
    ROLE_NAME=$(cat api_response.json | jq -r .values.roleName)


    terraform init && terraform apply -auto-approve

    echo "  Initializing Terraform modules, backend and provider plugins" \
    && terraform init >> ${OUTPUT} 2>&1 \
    && echo "    Terraform has been successfully initialized. Applying... (this will take a few minutes)" \
    && terraform apply -auto-approve \
        >> ${OUTPUT} 2>&1 \
    && echo "    Terraform apply completed! Check all TF deployment logs at: $OUTPUT"

    # onboard AWS account
    ACCOUNT_ID_INTERNAL=$(curl -s -k -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${SYSDIG_SECURE_API_TOKEN}" \
        --data '{
            "enabled": true,
            "provider": "PROVIDER_AWS",
            "providerId": "'${AWS_ACCOUNT_ID}'"
        }' \
        "${SECURE_API_ENDPOINT}/api/cloudauth/v1/accounts" | jq -r '.id')

    # enable components
    cat api_response.json | jq -c '.accountConfig.components[]' | while read -r data; 
        do
            echo "Adding component: $data"
            echo ""
            curl -s -k -X POST \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer ${SYSDIG_SECURE_API_TOKEN}" \
                --data "$data" \
                "${SECURE_API_ENDPOINT}/api/cloudauth/v1/accounts/${ACCOUNT_ID_INTERNAL}/components"
            echo ""
        done

    # add features
    cat api_response.json | jq -c '.accountConfig.features[]' | while read -r data;
        do
            FEATURE=$(echo $data | jq -r .type)
            echo "Adding feature: ${FEATURE}"
            curl -s -k -X PUT \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer ${SYSDIG_SECURE_API_TOKEN}" \
                --data "$data" \
                "${SECURE_API_ENDPOINT}/api/cloudauth/v1/accounts/${ACCOUNT_ID_INTERNAL}/feature/${FEATURE}"
            echo ""
        done

    # enable CIEM

    curl -s -k -X PUT \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${SYSDIG_SECURE_API_TOKEN}" \
        --data '{
        "accountId": "'${AWS_ACCOUNT_ID}'",
        "provider": "aws",
        "alias": "'${RANDOM_ID}'",
        "roleAvailable": true,
        "roleName": "'${ROLE_NAME}'",
        "ciemEnabled": true
        }' \
        ${SECURE_API_ENDPOINT}/api/cloud/v2/accounts/${AWS_ACCOUNT_ID} \
        | jq

fi

if [ "$PROVIDER" == "gcp" ]
then
    cd gcp
    echo "  Initializing Terraform modules, backend and provider plugins" \
    && terraform init >> ${OUTPUT} 2>&1 \
    && echo "    Terraform has been successfully initialized. Applying... (this will take a few minutes)" \
    && terraform apply -auto-approve \
        -var="training_secure_api_token=$SYSDIG_SECURE_API_TOKEN" \
        -var="training_secure_url=$SECURE_API_ENDPOINT" \
        -var="training_gcp_region=$CLOUD_REGION" \
        -var="training_gcp_project=$CLOUD_ACCOUNT_ID" \
        -var="gcp_creds=$GOOGLE_CREDENTIALS" \
        -var="deploy_scanner=$USE_CLOUD_SCAN_ENGINE" \
        >> ${OUTPUT} 2>&1 \
    && echo "    Terraform apply completed! Check all TF deployment logs at: $OUTPUT"
fi

if [ "$PROVIDER" == "azure" ]
then
    cd azure
    terraform init && terraform apply -auto-approve \
        -var="training_secure_api_token=$SYSDIG_SECURE_API_TOKEN" \
        -var="training_secure_url=$SECURE_API_ENDPOINT" \
        -var="training_azure_subscription=$CLOUD_ACCOUNT_ID" #\
        #-y >> ${OUTPUT} 2>&1
fi
