#!/usr/bin/env bash
##
# Deploy the Sysdig Secure for Cloud infra for different cloud vendors
#
# Usage:
#   install_with_terraform.sh $PROVIDER $SYSDIG_SECURE_API_TOKEN $SECURE_API_ENDPOINT $CLOUD_REGION $CLOUD_ACCOUNT_ID
##

# logs
OUTPUT=/opt/sysdig/cloud/terraform_uninstall.out
mkdir -p /opt/sysdig/cloud/
touch $OUTPUT

PROVIDER=$1
SYSDIG_SECURE_API_TOKEN=$2
SECURE_API_ENDPOINT=$3
CLOUD_REGION=$4
CLOUD_ACCOUNT_ID=$5

cd /root/prepare-track/cloud

if [ "$PROVIDER" == "aws" ]
then
    cd aws
    echo "    Terraform is deleting the cloud account integration. Deleting... (this will take a few minutes)" \
    && terraform destroy -auto-approve \
        -var="training_secure_api_token=$SYSDIG_SECURE_API_TOKEN" \
        -var="training_secure_url=$SECURE_API_ENDPOINT" \
        -var="training_aws_region=$CLOUD_REGION" \
        >> ${OUTPUT} 2>&1 \
    && echo "    Terraform destroy completed! Check all TF deployment logs at: $OUTPUT"
fi