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

if [ $# -ne 6 ]
  then
    echo "$0: Provide 6 arguments: "
    echo "$0: Defaulting to training account."

    ACCOUNT_PROVISIONER_MONITOR_API_TOKEN="${DYNAMIC_MONITOR_API:-$TRAINING_US_MONITOR_API_TOKEN}"
    ACCOUNT_PROVISIONER_MONITOR_API_URL="${DYNAMIC_MONITOR_API_URL:-https://us2.app.sysdig.com}"
    ACCOUNT_PROVISIONER_SECURE_API_TOKEN="${DYNAMIC_SECURE_API:-$TRAINING_US_SECURE_API_TOKEN}"
    ACCOUNT_PROVISIONER_SECURE_API_URL="${DYNAMIC_SECURE_API_URL:-https://us2.app.sysdig.com}"
    ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY="${DYNAMIC_AGENT_ACCESS_KEY:-$TRAINING_US_AGENT_ACCESS_KEY}"
    ACCOUNT_PROVISIONER_REGION_NUMBER="${TEST_REGION:-2}"
    DYNAMIC_PROVISIONER_MONITOR_ONLY="${DYNAMIC_PROVISIONER_MONITOR_ONLY:-false}"
    DYNAMIC_PROVISIONER_SECURE_ONLY="${DYNAMIC_PROVISIONER_SECURE_ONLY:-false}"
else
    ACCOUNT_PROVISIONER_MONITOR_API_TOKEN=$1
    ACCOUNT_PROVISIONER_MONITOR_API_URL=$2
    ACCOUNT_PROVISIONER_SECURE_API_TOKEN=$3
    ACCOUNT_PROVISIONER_SECURE_API_URL=$4
    ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY=$5
    ACCOUNT_PROVISIONER_REGION_NUMBER=$6
    DYNAMIC_PROVISIONER_MONITOR_ONLY="${DYNAMIC_PROVISIONER_MONITOR_ONLY:-false}"
    DYNAMIC_PROVISIONER_SECURE_ONLY="${DYNAMIC_PROVISIONER_SECURE_ONLY:-false}"
fi

WORK_DIR=/opt/sysdig
TRACK_DIR=/tmp/instruqt-assets/common/prepare-track
mkdir -p $WORK_DIR
mkdir -p $TRACK_DIR

# Decode the base64 credentials
ACCOUNT_PROVISIONER_MONITOR_API_TOKEN=$(echo -n ${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN} | base64 --decode)
ACCOUNT_PROVISIONER_SECURE_API_TOKEN=$(echo -n ${ACCOUNT_PROVISIONER_SECURE_API_TOKEN} | base64 --decode)
ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY=$(echo -n ${ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY} | base64 --decode)

# persist values
echo "${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}" > $WORK_DIR/ACCOUNT_PROVISIONER_MONITOR_API_TOKEN
echo "${ACCOUNT_PROVISIONER_MONITOR_API_URL}" > $WORK_DIR/ACCOUNT_PROVISIONER_MONITOR_API_URL
echo "${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}" > $WORK_DIR/ACCOUNT_PROVISIONER_SECURE_API_TOKEN
echo "${ACCOUNT_PROVISIONER_SECURE_API_URL}" > $WORK_DIR/ACCOUNT_PROVISIONER_SECURE_API_URL
echo "${ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY}" > $WORK_DIR/ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY
echo "${ACCOUNT_PROVISIONER_REGION_NUMBER}" > $WORK_DIR/ACCOUNT_PROVISIONER_REGION # check region ids in init.sh

source $TRACK_DIR/lab_random_string_id.sh

function provsion_user(){
  # create user in parent account
  curl -s -k -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $1" \
  --data-binary '{
  "username": "'"${SPA_USER}"'",
  "password": "'"${SPA_PASS}"'",
  "firstName": "Id:",
  "lastName": "'"${SPA_USER}"'",
  "systemRole": "ROLE_USER"
  }' \
  "${ACCOUNT_PROVISIONER_SECURE_API_URL}"/api/user/provisioning/ \
  | jq > $WORK_DIR/account.json
}

# define new user creds, and feed it to instruqt lab as an agent var
WORK_DIR=/opt/sysdig
SPA_PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo '')
echo "${SPA_PASS}"
echo "${SPA_PASS}" > $WORK_DIR/ACCOUNT_PROVISIONED_PASS
agent variable set SPA_PASS "${SPA_PASS}"
# we use the same two random dictionary words to set user_name and cluster_name 
SPA_USER=$(cat $WORK_DIR/ACCOUNT_PROVISIONED_USER)
echo "${SPA_USER}"
agent variable set SPA_USER "${SPA_USER}"
if [ $DYNAMIC_PROVISIONER_MONITOR_ONLY == "true" ]; then
  agent variable set SPA_MONITOR_API_TOKEN "${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}"
  agent variable set SPA_MONITOR_API_URL "${ACCOUNT_PROVISIONER_MONITOR_API_URL}"
else
  agent variable set SPA_SECURE_API_TOKEN "${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}"
  agent variable set SPA_MONITOR_API_TOKEN "${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}"
  agent variable set SPA_SECURE_API_URL "${ACCOUNT_PROVISIONER_SECURE_API_URL}"
  agent variable set SPA_MONITOR_API_URL "${ACCOUNT_PROVISIONER_MONITOR_API_URL}"
fi
PROVISIONED_RANDOM_ID=$(cat $WORK_DIR/random_string_OK)
agent variable set PROVISIONED_RANDOM_ID "${PROVISIONED_RANDOM_ID}"

# create user in parent account
if [ $DYNAMIC_PROVISIONER_MONITOR_ONLY == "true" ]; then
    echo "Monitor provisioning only"
    provsion_user "${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}"
else
    echo "Secure and Monitor provisioning"
    provsion_user "${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}"
fi

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
--data-binary @- \
"${ACCOUNT_PROVISIONER_SECURE_API_URL}"/api/secure/onboarding/v2/userProfile/questionnaire <<EOF > /dev/null
[
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
]
EOF

# get monitor operations team info
if [ $DYNAMIC_PROVISIONER_SECURE_ONLY != "true" ]; then
  # Get monitor operations team ID
  MONITOR_OPS_TEAM_ID=$(curl -s -k -X GET \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}" \
  "${ACCOUNT_PROVISIONER_MONITOR_API_URL}/api/v3/teams?filter=product:SDC&offset=0&orderBy=name:asc" | jq -r '.data[] | select(.name == "Monitor Operations") | .id')
  if [ -z "$MONITOR_OPS_TEAM_ID" ]; then
      echo "Monitor Operations team not found"
      exit 1
  fi
  # Get the account ID
  echo "Monitor Operations team ID: $MONITOR_OPS_TEAM_ID"

  curl -s -k -X GET \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}" \
  "${ACCOUNT_PROVISIONER_MONITOR_API_URL}"/api/teams/${MONITOR_OPS_TEAM_ID} \
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
          "userId": '"${SPA_USER_ID}"',
          "userName": "'"${SPA_USER}"'",
          "role": "ROLE_TEAM_STANDARD"
      }' "$WORK_DIR/monitor-operations-team.json" > "$WORK_DIR/monitor-operations-team.json.tmp"
  cp "$WORK_DIR/monitor-operations-team.json.tmp" "$WORK_DIR/monitor-operations-team.json"
  rm "$WORK_DIR/monitor-operations-team.json.tmp"


  # update Monitor Operations team with new user assigned
  curl -s -k -X PUT \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}" \
  -d @$WORK_DIR/monitor-operations-team.json \
  "${ACCOUNT_PROVISIONER_MONITOR_API_URL}"/api/teams/${MONITOR_OPS_TEAM_ID} \
  | jq > /dev/null
fi
