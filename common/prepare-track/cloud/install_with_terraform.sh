#!/usr/bin/env bash
##
# Deploy the Sysdig Secure for Cloud infra for different cloud vendors
#
# Usage:
#   install_with_terraform.sh $PROVIDER $SYSDIG_SECURE_API_TOKEN $SECURE_URL $CLOUD_REGION $CLOUD_ACCOUNT_ID
##

# logs
OUTPUT=/opt/sysdig/cloud/terraform_install.out
mkdir -p /opt/sysdig/cloud/
touch $OUTPUT

PROVIDER=$1
SYSDIG_SECURE_API_TOKEN=$2
SECURE_URL=$3
CLOUD_REGION=$4
CLOUD_ACCOUNT_ID=$5

cd /root/prepare-track/cloud

if [ "$PROVIDER" == "aws" ]
then
    cd aws
    echo "  Initializing Terraform modules, backend and provider plugins" \
    && terraform init >> ${OUTPUT} 2>&1 \
    && echo "    Terraform has been successfully initialized. Applying... (this will take a few minutes)" \
    && terraform apply -auto-approve \
        -var="training_secure_api_token=$SYSDIG_SECURE_API_TOKEN" \
        -var="training_secure_url=$SECURE_URL" \
        -var="training_aws_region=$CLOUD_REGION" \
        -var="deploy_scanner=$CLOUD_SCAN_ENGINE" \
        >> ${OUTPUT} 2>&1 \
    && echo "    Terraform apply completed! Check all TF deployment logs at: $OUTPUT"
fi

if [ "$PROVIDER" == "gcp" ]
then
    cd gcp
    echo "  Initializing Terraform modules, backend and provider plugins" \
    && terraform init >> ${OUTPUT} 2>&1 \
    && echo "    Terraform has been successfully initialized. Applying... (this will take a few minutes)" \
    && terraform apply -auto-approve \
        -var="training_secure_api_token=$SYSDIG_SECURE_API_TOKEN" \
        -var="training_secure_url=$SECURE_URL" \
        -var="training_gcp_region=$CLOUD_REGION" \
        -var="training_gcp_project=$CLOUD_ACCOUNT_ID" \
        -var="gcp_creds=$GOOGLE_CREDENTIALS" \
        -var="deploy_scanner=$CLOUD_SCAN_ENGINE" \
        >> ${OUTPUT} 2>&1 \
    && echo "    Terraform apply completed! Check all TF deployment logs at: $OUTPUT"
fi

if [ "$PROVIDER" == "azure" ]
then
    cd azure
    terraform init && terraform apply -auto-approve \
        -var="training_secure_api_token=$SYSDIG_SECURE_API_TOKEN" \
        -var="training_secure_url=$SECURE_URL" \
        -var="training_azure_subscription=$CLOUD_ACCOUNT_ID" \
        -var="deploy_scanner=$CLOUD_SCAN_ENGINE" #\
        #-y >> ${OUTPUT} 2>&1
fi