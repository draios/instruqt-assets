#!/bin/bash

set -xe

WORK_DIR=/opt/sysdig
mkdir -p $WORK_DIR

##
# User deprovisioner
##
function user_deprovisioner () {

    # parent account data
    ACCOUNT_PROVISIONER_SECURE_API_TOKEN=17f43073-96e4-4221-9117-65ac17eaa84d
    ACCOUNT_PROVISIONER_SECURE_API_URL=https://secure.sysdig.com
    SPA_USER=$(cat $WORK_DIR/ACCOUNT_PROVISIONED_USER)

    # delete user in parent account
    curl -s -k -X DELETE \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}" \
    ${ACCOUNT_PROVISIONER_SECURE_API_URL}/api/users/${SPA_USER} \
    | jq > $WORK_DIR/delete-user.json

}

user_deprovisioner