#!/bin/bash

set -xe

WORK_DIR=/opt/sysdig
mkdir -p $WORK_DIR

##
# User provisioner, creates a user in a general training Sysdig account
# so the user does not have to use its own.
##
function user_provisioner () {
    # parent account data
    ACCOUNT_PROVISIONER_SECURE_API_TOKEN=[REDACTED]
    ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY=[REDACTED]
    ACCOUNT_PROVISIONER_SECURE_API_URL=https://us2.app.sysdig.com
    echo "${ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY}" > $WORK_DIR/ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY

    # new user creds
    SPA_PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo '')
    echo ${SPA_PASS}
    echo "${SPA_PASS}" > $WORK_DIR/ACCOUNT_PROVISIONED_PASS
    agent variable set SPA_PASS ${SPA_PASS}

    SPA_USER=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 3 ; echo '')
    SPA_USER=sysdig_pa_$(date +%Y%m%d)_${SPA_USER}@sysdig.com
    echo ${SPA_USER}
    echo "${SPA_USER}" > $WORK_DIR/ACCOUNT_PROVISIONED_USER
    agent variable set SPA_USER ${SPA_USER}



    # always disable onboarding, just in case someone enables it
    curl -k -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}" \
    --data-binary '{ "onboardingEnabled": false }' \
    ${ACCOUNT_PROVISIONER_SECURE_API_URL}/api/secure/onboarding/v2/feature/status \
    | jq > $WORK_DIR/account.json

    # create user in parent account
    curl -s -k -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}" \
    --data-binary '{
    "username": "'${SPA_USER}'",
    "password": "'${SPA_PASS}'",
    "firstName": "Training", 
    "lastName": "Student", 
    "systemRole": "WORKSHOP_USER" 
    }' \
    ${ACCOUNT_PROVISIONER_SECURE_API_URL}/api/user/provisioning/ \
    | jq > $WORK_DIR/account.json
    # todo proceed only if successful

    # we reuse the existing test data, add here the new credentials
    # also, we guarantee that for runs where both conditions (is_test_run AND user_provisioner) are meet
    # we test it with the user provisioned data
    # check f() overwrite_test_creds in init.sh for more info

    # set flag user provisioned
    touch $WORK_DIR/user_provisioned_COMPLETED
}

user_provisioner