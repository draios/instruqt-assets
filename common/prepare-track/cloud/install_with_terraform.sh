#!/usr/bin/env bash
##
# Deploy the Sysdig Secure for Cloud infra for different cloud vendors
#
# Usage:
#   install_with_terraform.sh $PROVIDER $SYSDIG_SECURE_API_TOKEN $SECURE_API_ENDPOINT $CLOUD_REGION $CLOUD_ACCOUNT_ID
##

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

# Config git to use the PAT for access to the terraform modules in our private repo
# This is needed to avoid the need for a password when cloning the repo
# The PAT is stored in the environment variable Terraform_Modules_PAT coming from the Instruqt environment
git config --global url."https://sysdiglabs:$Terraform_Modules_PAT@github.com".insteadOf https://github.com

if [ "$PROVIDER" == "aws" ]
then
    cd aws
    echo "  Initializing Terraform modules, backend and provider plugins" \
    && terraform init >> ${OUTPUT} 2>&1 \
    && echo "    Terraform has been successfully initialized. Applying... (this will take a few minutes)" \
    && terraform apply -auto-approve -var="training_aws_region=$CLOUD_REGION" \
        -var="scanning_account_id=878070807337" \
        -var="training_secure_api_token=$SYSDIG_SECURE_API_TOKEN" \
        -var="training_secure_url=$SECURE_API_ENDPOINT" >> ${OUTPUT} 2>&1 \
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
        -var="training_secure_url=$SECURE_API_ENDPOINT" \
        -var="training_gcp_region=$CLOUD_REGION" \
        -var="training_gcp_project=$CLOUD_ACCOUNT_ID" \
        -var="gcp_creds=$GOOGLE_CREDENTIALS" \
        >> ${OUTPUT} 2>&1 \
    && echo "    Terraform apply completed! Check all TF deployment logs at: $OUTPUT"
fi

if [ "$PROVIDER" == "azure" ]
then
    cd azure
    echo "  Initializing Terraform modules, backend and provider plugins" \
    && terraform init >> ${OUTPUT} 2>&1 \
    && echo "    Terraform has been successfully initialized. Applying... (this will take a few minutes)" \
    && terraform apply -auto-approve \
        -var="training_secure_api_token=$SYSDIG_SECURE_API_TOKEN" \
        -var="training_secure_url=$SECURE_API_ENDPOINT" \
        -var="training_azure_subscription=$CLOUD_ACCOUNT_ID" \
        -var="training_azure_tenant_id=$AZURE_TENANT_ID" \
        >> ${OUTPUT} 2>&1 \
    && echo "    Terraform apply completed! Check all TF deployment logs at: $OUTPUT"
fi
