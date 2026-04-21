#!/bin/bash

set -xeo pipefail

WORK_DIR=/opt/sysdig

##
# User deprovisioner
##
function user_deprovisioner () {
    if [ ! -f "$WORK_DIR/ACCOUNT_PROVISIONED_USER" ]; then
        echo "No provisioned user found. Skipping deprovisioning."
        return 0
    fi

    # parent account data
    ACCOUNT_PROVISIONER_SECURE_API_TOKEN=$(<"$WORK_DIR/ACCOUNT_PROVISIONER_SECURE_API_TOKEN")
    ACCOUNT_PROVISIONER_SECURE_API_URL=$(<"$WORK_DIR/ACCOUNT_PROVISIONER_SECURE_API_URL")
    SPA_USER=$(<"$WORK_DIR/ACCOUNT_PROVISIONED_USER")

    # delete user in parent account
    curl -s -k -X DELETE \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}" \
    "${ACCOUNT_PROVISIONER_SECURE_API_URL}/api/users/${SPA_USER}" \
    | jq > /dev/null || true
}

user_deprovisioner
