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
    echo "    Terraform is deleting the cloud account integratoin. Deleting... (this will take a few minutes)" \
    && terraform destroy -auto-approve \
        -var="training_secure_api_token=$SYSDIG_SECURE_API_TOKEN" \
        -var="training_secure_url=$SECURE_API_ENDPOINT" \
        -var="training_aws_region=$CLOUD_REGION" \
        >> ${OUTPUT} 2>&1 \
    && echo "    Terraform destroy completed! Check all TF deployment logs at: $OUTPUT"
fi

# if [ "$PROVIDER" == "gcp" ]
# then
#     cd gcp
#     echo "  Initializing Terraform modules, backend and provider plugins" \
#     && terraform init >> ${OUTPUT} 2>&1 \
#     && echo "    Terraform has been successfully initialized. Applying... (this will take a few minutes)" \
#     && terraform apply -auto-approve \
#         -var="training_secure_api_token=$SYSDIG_SECURE_API_TOKEN" \
#         -var="training_secure_url=$SECURE_API_ENDPOINT" \
#         -var="training_gcp_region=$CLOUD_REGION" \
#         -var="training_gcp_project=$CLOUD_ACCOUNT_ID" \
#         -var="gcp_creds=$GOOGLE_CREDENTIALS" \
#         -var="deploy_scanner=$USE_CLOUD_SCAN_ENGINE" \
#         >> ${OUTPUT} 2>&1 \
#     && echo "    Terraform apply completed! Check all TF deployment logs at: $OUTPUT"
# fi

# if [ "$PROVIDER" == "azure" ]
# then
#     cd azure
#     terraform init && terraform apply -auto-approve \
#         -var="training_secure_api_token=$SYSDIG_SECURE_API_TOKEN" \
#         -var="training_secure_url=$SECURE_API_ENDPOINT" \
#         -var="training_azure_subscription=$CLOUD_ACCOUNT_ID" #\
#         #-y >> ${OUTPUT} 2>&1
# fi