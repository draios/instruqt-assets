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
    echo "$0: Provide 6 arguments: Monitor API token, Monitor API URL, Secure API token, Secure API URL, Agent Key, region number (see init.sh)"
    echo "$0: Defaulting to training account."
    
    # parent account data, we create with pablo.lopezzaldivar+training@sysdig.com token
    ACCOUNT_PROVISIONER_MONITOR_API_TOKEN=970a55f3-889e-4c80-9f73-3dba104ccb53
    ACCOUNT_PROVISIONER_MONITOR_API_URL=https://us2.app.sysdig.com
    ACCOUNT_PROVISIONER_SECURE_API_TOKEN=cce028ab-d10b-48e2-92d6-389317d9d92e
    ACCOUNT_PROVISIONER_SECURE_API_URL=https://us2.app.sysdig.com
    ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY=9f1c06cf-f7ee-45b8-943f-73740472e978
    ACCOUNT_PROVISIONER_REGION_NUMBER=2
else
    ACCOUNT_PROVISIONER_MONITOR_API_TOKEN=$1
    ACCOUNT_PROVISIONER_MONITOR_API_URL=$2
    ACCOUNT_PROVISIONER_SECURE_API_TOKEN=$3
    ACCOUNT_PROVISIONER_SECURE_API_URL=$4
    ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY=$5
    ACCOUNT_PROVISIONER_REGION_NUMBER=$6
fi

WORK_DIR=/opt/sysdig
mkdir -p $WORK_DIR

# persist values
echo "${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}" > $WORK_DIR/ACCOUNT_PROVISIONER_MONITOR_API_TOKEN
echo "${ACCOUNT_PROVISIONER_MONITOR_API_URL}" > $WORK_DIR/ACCOUNT_PROVISIONER_MONITOR_API_URL
echo "${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}" > $WORK_DIR/ACCOUNT_PROVISIONER_SECURE_API_TOKEN
echo "${ACCOUNT_PROVISIONER_SECURE_API_URL}" > $WORK_DIR/ACCOUNT_PROVISIONER_SECURE_API_URL
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
# this is not working today, always return "onboardingEnabled":true (reported)
# curl -s -k -X POST \
# -H "Content-Type: application/json" \
# -H "Authorization: Bearer ${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}" \
# --data-binary '{
#     "onboardingEnabled":false,
#     "newOnboardingWizard":false,
#     "falcoCloudEnabled":false,
#     "falcoCloudBetaFlows":false,
#     "onboardingSkipped":false,
#     "oktaEnabled":false}' \
# ${ACCOUNT_PROVISIONER_SECURE_API_URL}/api/secure/onboarding/v2/feature/status \
# | jq > /dev/null

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
]' ${ACCOUNT_PROVISIONER_SECURE_API_URL}/api/secure/onboarding/v2/userProfile/questionnaire \
| jq > /dev/null

# TODO: get monitor operations team ID
MONITOR_OPS_TEAM_ID=10018845

# get monitor operations team info
curl -s -k -X GET \
-H "Content-Type: application/json" \
-H "Authorization: Bearer ${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}" \
${ACCOUNT_PROVISIONER_MONITOR_API_URL}/api/teams/${MONITOR_OPS_TEAM_ID} \
| jq > $WORK_DIR/monitor-operations-team.json

# edits
#   remove team, get all other info
jq '.team' "$WORK_DIR/monitor-operations-team.json" > "$WORK_DIR/monitor-operations-team.json.tmp"
cp "$WORK_DIR/monitor-operations-team.json.tmp" "$WORK_DIR/monitor-operations-team.json"
rm "$WORK_DIR/monitor-operations-team.json.tmp"

#   update version
# jq '.version += 1' "$WORK_DIR/monitor-operations-team.json" > "$WORK_DIR/monitor-operations-team.json.tmp"
# cp "$WORK_DIR/monitor-operations-team.json.tmp" "$WORK_DIR/monitor-operations-team.json"
# rm "$WORK_DIR/monitor-operations-team.json.tmp"

# remove all users that are role ROLE_TEAM_MANAGER
jq '.userRoles[] |= del(. | select(.role == "ROLE_TEAM_MANAGER"))' "$WORK_DIR/monitor-operations-team.json" > "$WORK_DIR/monitor-operations-team.json.tmp"
cp "$WORK_DIR/monitor-operations-team.json.tmp" "$WORK_DIR/monitor-operations-team.json"
rm "$WORK_DIR/monitor-operations-team.json.tmp"

# clean nulls in .userRoles[]
# del(.[][] | nulls)
jq '.userRoles |= del(.[] | nulls)' "$WORK_DIR/monitor-operations-team.json" > "$WORK_DIR/monitor-operations-team.json.tmp"
cp "$WORK_DIR/monitor-operations-team.json.tmp" "$WORK_DIR/monitor-operations-team.json"
rm "$WORK_DIR/monitor-operations-team.json.tmp"

# remove fields         "properties" "customerId" "dateCreated" "lastUpdated" "userCount"
jq '. |= del(.properties)' "$WORK_DIR/monitor-operations-team.json" > "$WORK_DIR/monitor-operations-team.json.tmp"
cp "$WORK_DIR/monitor-operations-team.json.tmp" "$WORK_DIR/monitor-operations-team.json"
rm "$WORK_DIR/monitor-operations-team.json.tmp"
jq '. |= del(.customerId)' "$WORK_DIR/monitor-operations-team.json" > "$WORK_DIR/monitor-operations-team.json.tmp"
cp "$WORK_DIR/monitor-operations-team.json.tmp" "$WORK_DIR/monitor-operations-team.json"
rm "$WORK_DIR/monitor-operations-team.json.tmp"
jq '. |= del(.dateCreated)' "$WORK_DIR/monitor-operations-team.json" > "$WORK_DIR/monitor-operations-team.json.tmp"
cp "$WORK_DIR/monitor-operations-team.json.tmp" "$WORK_DIR/monitor-operations-team.json"
rm "$WORK_DIR/monitor-operations-team.json.tmp"
jq '. |= del(.lastUpdated)' "$WORK_DIR/monitor-operations-team.json" > "$WORK_DIR/monitor-operations-team.json.tmp"
cp "$WORK_DIR/monitor-operations-team.json.tmp" "$WORK_DIR/monitor-operations-team.json"
rm "$WORK_DIR/monitor-operations-team.json.tmp"
jq '. |= del(.userCount)' "$WORK_DIR/monitor-operations-team.json" > "$WORK_DIR/monitor-operations-team.json.tmp"
cp "$WORK_DIR/monitor-operations-team.json.tmp" "$WORK_DIR/monitor-operations-team.json"
rm "$WORK_DIR/monitor-operations-team.json.tmp"

# add fields   "searchFilter" "filter"
jq --argjson var null '. + {searchFilter: $var}' "$WORK_DIR/monitor-operations-team.json" > "$WORK_DIR/monitor-operations-team.json.tmp"
cp "$WORK_DIR/monitor-operations-team.json.tmp" "$WORK_DIR/monitor-operations-team.json"
rm "$WORK_DIR/monitor-operations-team.json.tmp"
jq --argjson var null '. + {filter: $var}' "$WORK_DIR/monitor-operations-team.json" > "$WORK_DIR/monitor-operations-team.json.tmp"
cp "$WORK_DIR/monitor-operations-team.json.tmp" "$WORK_DIR/monitor-operations-team.json"
rm "$WORK_DIR/monitor-operations-team.json.tmp"

# add new user to group
# this is not working, we should remove existing users (account managers) and push only the new ones. 
# the get is returning account_managers
jq '.userRoles[.userRoles| length] |= . + {
        "teamId": '${MONITOR_OPS_TEAM_ID}',
        "teamName": "Monitor Operations",
        "teamTheme": "#7BB0B2",
        "userId": '${SPA_USER_ID}',
        "userName": "'${SPA_USER}'",
        "role": "ROLE_TEAM_STANDARD"
    }' "$WORK_DIR/monitor-operations-team.json" > "$WORK_DIR/monitor-operations-team.json.tmp"
cp "$WORK_DIR/monitor-operations-team.json.tmp" "$WORK_DIR/monitor-operations-team.json"
rm "$WORK_DIR/monitor-operations-team.json.tmp"


# update Monitor Operations team with new user assigned
curl -s -k -X PUT \
-H "Content-Type: application/json" \
-H "Authorization: Bearer ${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}" \
-d @$WORK_DIR/monitor-operations-team.json \
${ACCOUNT_PROVISIONER_MONITOR_API_URL}/api/teams/${MONITOR_OPS_TEAM_ID} \
| jq > /dev/null
