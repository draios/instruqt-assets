#!/bin/bash

set -xe

##
# User provisioner, creates a user in a general training Sysdig account
# so the user does not have to use its own.
##
function user_provisioner () {
    # parent account data
    ACCOUNT_PROVISIONER_SECURE_API_TOKEN=17f43073-96e4-4221-9117-65ac17eaa84d
    ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY=d5ef4566-d0c2-4174-92eb-0727fc0991f3
    echo "${ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY}" > $WORK_DIR/ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY
    ACCOUNT_PROVISIONER_REGION=1

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
    ${SECURE_API_URL}/api/secure/onboarding/v2/feature/status \
    | jq > /opt/sysdig/account.json

    # create user in parent account
    curl -s -k -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}" \
    --data-binary '{
    "username": "'${SPA_USER}'",
    "password": "'${SPA_PASS}'",
    "firstName": "Training", 
    "lastName": "Student", 
    "systemRole": "ROLE_USER" 
    }' \
    ${SECURE_API_URL}/api/user/provisioning/ \
    | jq > $WORK_DIR/account.json
    # todo proceed only if successful

    # we reuse the existing test data, add here the new credentials
    # also, we guarantee that for runs where both conditions (is_test_run AND user_provisioner) are meet
    # we test it with the user provisioned data
    # TEST_AGENT_ACCESS_KEY=$(echo ${ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY} | base64)
    # TEST_MONITOR_API=$(cat /opt/sysdig/account.json | jq --raw-output .token.key | base64)
    # TEST_SECURE_API=$(cat /opt/sysdig/account.json | jq --raw-output .token.key | base64)
    # TEST_REGION=2

    # adaptar
    # echo ${SPA_USER}
    # echo "${SPA_USER}" > $WORK_DIR/ACCOUNT_PROVISIONED_USER
    # agent variable set SPA_USER ${SPA_USER}

    # set flag user provisioned
    touch $WORK_DIR/user_provisioned_COMPLETED
}


user_provisioner