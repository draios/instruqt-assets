#!/bin/bash

set -xe

WORK_DIR=/opt/sysdig
mkdir -p $WORK_DIR

##
# User deprovisioner
##
function user_deprovisioner () {

    # parent account data
    ACCOUNT_PROVISIONER_SECURE_API_TOKEN=$(cat $WORK_DIR/ACCOUNT_PROVISIONER_SECURE_API_TOKEN)
    ACCOUNT_PROVISIONER_SECURE_API_URL=$(cat $WORK_DIR/ACCOUNT_PROVISIONER_SECURE_API_URL)
    SPA_USER=$(cat $WORK_DIR/ACCOUNT_PROVISIONED_USER)

    # delete user in parent account
    # TLS not validated (disabled): curl -s -k -X DELETE \
    curl -s -X DELETE \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}" \
    ${ACCOUNT_PROVISIONER_SECURE_API_URL}/api/users/${SPA_USER//+/%2B} \
    | jq

}

user_deprovisioner
