#!/bin/bash

set -xeo pipefail

WORK_DIR=/opt/sysdig

##
# User deprovisioner
##
function user_deprovisioner () {
    if [ ! -f "$WORK_DIR/account.json" ]; then
        echo "No provisioned user metadata found. Skipping deprovisioning."
        return 0
    fi

    # parent account data
    ACCOUNT_PROVISIONER_SECURE_API_TOKEN=$(<"$WORK_DIR/ACCOUNT_PROVISIONER_SECURE_API_TOKEN")
    ACCOUNT_PROVISIONER_SECURE_API_URL=$(<"$WORK_DIR/ACCOUNT_PROVISIONER_SECURE_API_URL")
    
    # Get user ID from the account.json created during provisioning
    # Note: The old provisioning API returns { "user": { "id": ... } }
    SPA_USER_ID=$(jq '.user.id' "$WORK_DIR/account.json")
    
    # API Base URL for Platform
    PLATFORM_API_URL=$(echo "${ACCOUNT_PROVISIONER_SECURE_API_URL}" | sed 's/app\./api./')

    if [ -n "$SPA_USER_ID" ] && [ "$SPA_USER_ID" != "null" ]; then
        echo "Deleting user ID: $SPA_USER_ID"
        # delete user in parent account using Platform API v1
        curl -s -k -X DELETE \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}" \
        "${PLATFORM_API_URL}/platform/v1/users/${SPA_USER_ID}" \
        | jq > /dev/null || true
    else
        echo "Could not find user ID in account.json. Attempting fallback delete by username..."
        SPA_USER=$(<"$WORK_DIR/ACCOUNT_PROVISIONED_USER")
        curl -s -k -X DELETE \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}" \
        "${ACCOUNT_PROVISIONER_SECURE_API_URL}/api/users/${SPA_USER}" \
        | jq > /dev/null || true
    fi
}

user_deprovisioner
