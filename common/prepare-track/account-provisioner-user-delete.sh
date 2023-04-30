#!/bin/bash

set -xe

##
# User deprovisioner
##
function user_deprovisioner () {
    # parent account data
    ACCOUNT_PROVISIONER_SECURE_API_TOKEN=17f43073-96e4-4221-9117-65ac17eaa84d
    echo "${ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY}" > $WORK_DIR/ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY
    ACCOUNT_PROVISIONER_REGION=1
    SECURE_API_URL=

    SPA_USER=$(cat $WORK_DIR/ACCOUNT_PROVISIONED_USER)

    # delete user in parent account
    curl -s -k -X DELETE \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}" \
    ${SECURE_API_URL}/api/users:"'${SPA_USER}'" \
    | jq > $WORK_DIR/delete-user.json

}


user_deprovisioner