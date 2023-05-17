#!/bin/bash
##
# User provisioner, creates a user in a general training Sysdig account
# so the user does not have to use its own.
#
# NOTE:
# we reuse the existing test data inside of the init.sh script, add here the new credentials
# also, we guarantee that for runs where both conditions (is_test_run AND user_provisioner) are meet
# we test it with the user provisioned data
# check f() overwrite_test_creds in init.sh for more info
# TODO: merge both approaches, from a functional lab perspective, both are the same
##

set -euxo pipefail

if [ $# -ne 4 ]
  then
    echo "$0: Provide 3 arguments: Secure API token, Secure API URL, Agent Key, region number (see init.sh)"
    echo "$0: Defaulting to training account."
    
    # parent account data, we create with pabloopez token
    ACCOUNT_PROVISIONER_SECURE_API_TOKEN=b77e2bde-d265-459f-ab9a-b209989f5373
    ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY=9f1c06cf-f7ee-45b8-943f-73740472e978
    ACCOUNT_PROVISIONER_SECURE_API_URL=https://us2.app.sysdig.com
    ACCOUNT_PROVISIONER_REGION_NUMBER=2
else
    ACCOUNT_PROVISIONER_SECURE_API_TOKEN=$1
    ACCOUNT_PROVISIONER_SECURE_API_URL=$2
    ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY=$3
    ACCOUNT_PROVISIONER_REGION_NUMBER=$4
fi

WORK_DIR=/opt/sysdig
mkdir -p $WORK_DIR

# persist values
echo "${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}" > $WORK_DIR/ACCOUNT_PROVISIONER_SECURE_API_TOKEN
echo "${ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY}" > $WORK_DIR/ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY
echo "${ACCOUNT_PROVISIONER_SECURE_API_URL}" > $WORK_DIR/ACCOUNT_PROVISIONER_SECURE_API_URL
echo "${ACCOUNT_PROVISIONER_REGION_NUMBER}" > $WORK_DIR/ACCOUNT_PROVISIONER_REGION # check region ids in init.sh

# define new user creds, and feed it to instruqt lab as an agent var
SPA_PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo '')
echo ${SPA_PASS}
echo "${SPA_PASS}" > $WORK_DIR/ACCOUNT_PROVISIONED_PASS
agent variable set SPA_PASS ${SPA_PASS}
SPA_USER=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 3 ; echo '')
SPA_USER=sysdig_pa_$(date +%Y%m%d)_${SPA_USER}@sysdig.com
echo ${SPA_USER}
echo "${SPA_USER}" > $WORK_DIR/ACCOUNT_PROVISIONED_USER
agent variable set SPA_USER ${SPA_USER}

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
${ACCOUNT_PROVISIONER_SECURE_API_URL}/api/user/provisioning/ \
| jq > $WORK_DIR/account.json
# todo proceed only if successful

# set flag user provisioned, all OK
touch $WORK_DIR/user_provisioned_COMPLETED

# disable onboarding, just in case someone enables it
curl -k -X POST \
-H "Content-Type: application/json" \
-H "Authorization: Bearer ${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}" \
--data-binary '{ "onboardingEnabled": false }' \
${ACCOUNT_PROVISIONER_SECURE_API_URL}/api/secure/onboarding/v2/feature/status \
| jq > $WORK_DIR/account.json
