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

set -exo pipefail

USE_MONITOR="$USE_MONITOR"

if [ $# -ne 4 ]
then
  echo "$0: Provide 4 arguments:  Monitor/Secure API token, Monitor/Secure API URL, Agent Key, region number (see init.sh)"
  echo "Set USE_MONITOR to create the user in Monitor, instead of Secure"
  exit 1
fi

ACCOUNT_PROVISIONER_API_TOKEN=$1
ACCOUNT_PROVISIONER_API_URL=$2
ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY=$3
ACCOUNT_PROVISIONER_REGION_NUMBER=$4

WORK_DIR=/opt/sysdig
TRACK_DIR=/tmp/instruqt-assets/common/prepare-track
mkdir -p $WORK_DIR
mkdir -p $TRACK_DIR

# persist values
if [ $USE_MONITOR ]
then
  echo "${ACCOUNT_PROVISIONER_API_TOKEN}" > $WORK_DIR/ACCOUNT_PROVISIONER_MONITOR_API_TOKEN
  echo "${ACCOUNT_PROVISIONER_API_URL}" > $WORK_DIR/ACCOUNT_PROVISIONER_MONITOR_API_URL
else
  echo "${ACCOUNT_PROVISIONER_API_TOKEN}" > $WORK_DIR/ACCOUNT_PROVISIONER_SECURE_API_TOKEN
  echo "${ACCOUNT_PROVISIONER_API_URL}" > $WORK_DIR/ACCOUNT_PROVISIONER_SECURE_API_URL
fi
echo "${ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY}" > $WORK_DIR/ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY
echo "${ACCOUNT_PROVISIONER_REGION_NUMBER}" > $WORK_DIR/ACCOUNT_PROVISIONER_REGION # check region ids in init.sh

source $TRACK_DIR/lab_random_string_id.sh

# define new user creds, and feed it to instruqt lab as an agent var
WORK_DIR=/opt/sysdig
SPA_PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo '')
echo ${SPA_PASS}
echo "${SPA_PASS}" > $WORK_DIR/ACCOUNT_PROVISIONED_PASS
agent variable set SPA_PASS ${SPA_PASS}
# we use the same two random dictionary words to set user_name and cluster_name 
SPA_USER=$(cat $WORK_DIR/ACCOUNT_PROVISIONED_USER)
echo ${SPA_USER}
agent variable set SPA_USER ${SPA_USER}

if [ $USE_MONITOR ]
then
  agent variable set SPA_MONITOR_API_TOKEN ${ACCOUNT_PROVISIONER_API_TOKEN}
else
  agent variable set SPA_SECURE_API_TOKEN ${ACCOUNT_PROVISIONER_API_TOKEN}
fi

# create user in parent account
curl -s -k -X POST \
-H "Content-Type: application/json" \
-H "Authorization: Bearer ${ACCOUNT_PROVISIONER_API_TOKEN}" \
--data-binary '{
"username": "'${SPA_USER}'",
"password": "'${SPA_PASS}'",
"firstName": "Training",
"lastName": "Student",
"systemRole": "ROLE_USER"
}' \
${ACCOUNT_PROVISIONER_API_URL}/api/user/provisioning/ \
| jq > $WORK_DIR/account.json
# todo proceed only if successful

# set flag user provisioned, all OK
touch $WORK_DIR/user_provisioned_COMPLETED

# get user id and API token
SPA_USER_ID=$(cat  $WORK_DIR/account.json | jq .user.id)
SPA_USER_API_TOKEN=$(cat  $WORK_DIR/account.json | jq -r  .token.key)

# disable onboarding for this particular user
curl -s -k -X POST \
-H "Content-Type: application/json" \
-H "Authorization: Bearer ${SPA_USER_API_TOKEN}" \
--data-binary '[
  {
    "id": "additionalEnvironments",
    "displayQuestion": "What are all the environments your company has?",
    "choices": []
  },
  {
    "id": "iacManifests",
    "displayQuestion": "Where do you store your Infrastructure as Code manifests?",
    "choices": []
  },
  {
    "id": "cicdTool",
    "displayQuestion": "What are your CI/CD tools?",
    "choices": []
  },
  {
    "id": "notificationChannels",
    "displayQuestion": "How do you want to be notified outside of Sysdig?",
    "choices": []
  }
]' ${ACCOUNT_PROVISIONER_API_URL}/api/secure/onboarding/v2/userProfile/questionnaire \
| jq > /dev/null