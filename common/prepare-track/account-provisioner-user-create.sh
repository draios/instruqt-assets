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
#
# POV_MODE (default true in this branch, see lab_random_string_id.sh):
#   - Secure only: the user is not added to the Monitor Operations team and the
#     Monitor token is optional. Set DYNAMIC_PROVISIONER_SECURE_ONLY=false to bring
#     the Monitor provisioning back.
#   - The user is named <adjective>_<noun>+pov@sysdig.com (first name <adjective>,
#     last name <noun>) and is promoted to admin through the Platform API.
#   POV_MODE=false keeps the previous behaviour (student user, Secure + Monitor).
##

set -euxo pipefail

if [ $# -ne 6 ]
  then
    echo "$0: Provide 6 arguments: "
    echo "$0: Defaulting to training account."

    ACCOUNT_PROVISIONER_MONITOR_API_TOKEN="${DYNAMIC_MONITOR_API:-${TRAINING_US_MONITOR_API_TOKEN:-}}"
    ACCOUNT_PROVISIONER_MONITOR_API_URL="${DYNAMIC_MONITOR_API_URL:-https://us2.app.sysdig.com}"
    ACCOUNT_PROVISIONER_SECURE_API_TOKEN="${DYNAMIC_SECURE_API:-$TRAINING_US_SECURE_API_TOKEN}"
    ACCOUNT_PROVISIONER_SECURE_API_URL="${DYNAMIC_SECURE_API_URL:-https://us2.app.sysdig.com}"
    ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY="${DYNAMIC_AGENT_ACCESS_KEY:-$TRAINING_US_AGENT_ACCESS_KEY}"
    ACCOUNT_PROVISIONER_REGION_NUMBER="${TEST_REGION:-2}"
else
    ACCOUNT_PROVISIONER_MONITOR_API_TOKEN=$1
    ACCOUNT_PROVISIONER_MONITOR_API_URL=$2
    ACCOUNT_PROVISIONER_SECURE_API_TOKEN=$3
    ACCOUNT_PROVISIONER_SECURE_API_URL=$4
    ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY=$5
    ACCOUNT_PROVISIONER_REGION_NUMBER=$6
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

DYNAMIC_PROVISIONER_MONITOR_ONLY="${DYNAMIC_PROVISIONER_MONITOR_ONLY:-false}"
# POV_MODE provisions in Secure only, unless explicitly asked otherwise
DYNAMIC_PROVISIONER_SECURE_ONLY="${DYNAMIC_PROVISIONER_SECURE_ONLY:-$POV_MODE}"

# Token used to provision and promote the user: the parent account admin one
if [ $DYNAMIC_PROVISIONER_MONITOR_ONLY == "true" ]; then
    PROVISIONER_TOKEN="${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}"
else
    PROVISIONER_TOKEN="${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}"
fi

# SPA_USER, SPA_FIRST_NAME and SPA_LAST_NAME from the random id of the lab
function load_user_identity(){
  SPA_USER=$(cat $WORK_DIR/ACCOUNT_PROVISIONED_USER)
  if [ "$POV_MODE" = true ]; then
    local random_id
    random_id=$(cat $WORK_DIR/random_string_OK)
    SPA_FIRST_NAME="${random_id%%_*}"   # adjective
    SPA_LAST_NAME="${random_id#*_}"     # noun
  else
    SPA_FIRST_NAME="Id:"
    SPA_LAST_NAME="${SPA_USER}"
  fi
}

function provsion_user(){
  # create user in parent account
  # TLS not validated (disabled): curl -s -k -X POST \
  curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $1" \
  --data-binary '{
  "username": "'"${SPA_USER}"'",
  "password": "'"${SPA_PASS}"'",
  "firstName": "'"${SPA_FIRST_NAME}"'",
  "lastName": "'"${SPA_LAST_NAME}"'",
  "systemRole": "ROLE_USER"
  }' \
  "${ACCOUNT_PROVISIONER_SECURE_API_URL}"/api/user/provisioning/ \
  | jq > $WORK_DIR/account.json
}

# Platform API host (the one with /platform/v1/...) for the parent account:
# https://api.<region>.sysdig.com on SaaS, the same host as the backend on-prem.
# Can be forced with ACCOUNT_PROVISIONER_PLATFORM_API_URL.
function platform_api_url(){
  if [ -n "${ACCOUNT_PROVISIONER_PLATFORM_API_URL:-}" ]; then
    echo "${ACCOUNT_PROVISIONER_PLATFORM_API_URL%/}"
    return
  fi
  local host="${ACCOUNT_PROVISIONER_SECURE_API_URL#*://}"
  host="${host%%/*}"
  host="${host%%:*}"
  # SaaS hosts are <region>.app.sysdig.com or app.<region>.sysdig.com
  if [[ $host =~ ^((us|eu|au|me|in|jp)[0-9])\.app\.sysdig\.com$ || $host =~ ^app\.((us|eu|au|me|in|jp)[0-9])\.sysdig\.com$ ]]; then
    echo "https://api.${BASH_REMATCH[1]}.sysdig.com"
  elif [[ $host == app.sysdigcloud.com || $host == secure.sysdig.com ]]; then
    echo "https://api.us1.sysdig.com"
  else
    echo "${ACCOUNT_PROVISIONER_SECURE_API_URL%/}"
  fi
}

# Make the provisioned user an admin.
# PUT /platform/v1/users/{userId} needs the current "version" of the user, and
# the names too, otherwise they are wiped to null.
function make_user_admin(){
  local api user_id user_json version http_code attempt
  api=$(platform_api_url)
  user_id=$(jq -r '.user.id // empty' $WORK_DIR/account.json)

  for attempt in 1 2 3; do
    if [ -n "$user_id" ]; then
      # TLS not validated (disabled): user_json=$(curl -s -k -H "Authorization: Bearer ${PROVISIONER_TOKEN}" \
      user_json=$(curl -s -H "Authorization: Bearer ${PROVISIONER_TOKEN}" \
        "${api}/platform/v1/users/${user_id}" || true)
    else
      user_json=""
    fi
    version=$(echo "$user_json" | jq -r '.version // empty' 2>/dev/null || true)
    if [ -z "$version" ]; then
      # fallback: look the user up by email
      # TLS not validated (disabled): user_json=$(curl -s -k -G -H "Authorization: Bearer ${PROVISIONER_TOKEN}" \
      user_json=$(curl -s -G -H "Authorization: Bearer ${PROVISIONER_TOKEN}" \
        --data-urlencode "filter=email:${SPA_USER}" "${api}/platform/v1/users" \
        | jq '.data[0] // {}' 2>/dev/null || echo '{}')
      user_id=$(echo "$user_json" | jq -r '.id // empty')
      version=$(echo "$user_json" | jq -r '.version // empty')
    fi

    if [ -n "$user_id" ] && [ -n "$version" ]; then
      # TLS not validated (disabled): http_code=$(curl -s -k -o $WORK_DIR/make_admin.json -w '%{http_code}' -X PUT \
      http_code=$(curl -s -o $WORK_DIR/make_admin.json -w '%{http_code}' -X PUT \
        -H "Authorization: Bearer ${PROVISIONER_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$(jq -n --argjson version "$version" --arg first "$SPA_FIRST_NAME" --arg last "$SPA_LAST_NAME" \
              '{version: $version, isAdmin: true, firstName: $first, lastName: $last}')" \
        "${api}/platform/v1/users/${user_id}" || true)
      if [[ $http_code == 2* ]]; then
        echo "User ${SPA_USER} (id ${user_id}) is admin now"
        return 0
      fi
      echo "Making ${SPA_USER} admin failed (attempt ${attempt}, HTTP ${http_code}): $(cat $WORK_DIR/make_admin.json 2>/dev/null)"
    else
      echo "User ${SPA_USER} not found in ${api} (attempt ${attempt})"
    fi
    sleep 2
  done
  return 1
}

# define new user creds, and feed it to instruqt lab as an agent var
WORK_DIR=/opt/sysdig
SPA_PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16 ; echo '')
echo "${SPA_PASS}"
echo "${SPA_PASS}" > $WORK_DIR/ACCOUNT_PROVISIONED_PASS

# create user in parent account. In POV mode the name has no salt: if it is
# already taken, pick another one.
for provision_attempt in 1 2 3 4 5; do
  load_user_identity
  if [ $DYNAMIC_PROVISIONER_MONITOR_ONLY == "true" ]; then
      echo "Monitor provisioning only"
  elif [ $DYNAMIC_PROVISIONER_SECURE_ONLY == "true" ]; then
      echo "Secure provisioning only"
  else
      echo "Secure and Monitor provisioning"
  fi
  provsion_user "${PROVISIONER_TOKEN}" || true

  if jq -e '.token.key' $WORK_DIR/account.json > /dev/null 2>&1 || [ "$POV_MODE" != true ]; then
    break
  fi
  echo "Provisioning ${SPA_USER} failed: $(jq -c . $WORK_DIR/account.json 2>/dev/null || cat $WORK_DIR/account.json)"
  echo "Trying with a different name (attempt ${provision_attempt})"
  rm -f $WORK_DIR/random_string_OK $WORK_DIR/ACCOUNT_PROVISIONED_USER
  generate_random_id
done

if [ "$POV_MODE" = true ] && ! jq -e '.token.key' $WORK_DIR/account.json > /dev/null 2>&1; then
  echo "Could not provision a user in ${ACCOUNT_PROVISIONER_SECURE_API_URL}"
  exit 1
fi

echo "${SPA_USER}"
agent variable set SPA_PASS "${SPA_PASS}"
agent variable set SPA_USER "${SPA_USER}"
if [ $DYNAMIC_PROVISIONER_MONITOR_ONLY == "true" ]; then
  agent variable set SPA_MONITOR_API_TOKEN "${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}"
  agent variable set SPA_MONITOR_API_URL "${ACCOUNT_PROVISIONER_MONITOR_API_URL}"
else
  agent variable set SPA_SECURE_API_TOKEN "${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}"
  agent variable set SPA_SECURE_API_URL "${ACCOUNT_PROVISIONER_SECURE_API_URL}"
  if [ $DYNAMIC_PROVISIONER_SECURE_ONLY != "true" ]; then
    agent variable set SPA_MONITOR_API_TOKEN "${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}"
    agent variable set SPA_MONITOR_API_URL "${ACCOUNT_PROVISIONER_MONITOR_API_URL}"
  fi
fi
PROVISIONED_RANDOM_ID=$(cat $WORK_DIR/random_string_OK)
agent variable set PROVISIONED_RANDOM_ID "${PROVISIONED_RANDOM_ID}"

# Make PROVISIONED_RANDOM_ID available to all future login shells
if [ -n "${PROVISIONED_RANDOM_ID:-}" ]; then
  # Export for the current shell (just in case)
  export PROVISIONED_RANDOM_ID

  # Persist it for all future login shells
  cat <<EOF >/etc/profile.d/provisioned_random_id.sh
export PROVISIONED_RANDOM_ID=$(printf '%q\n' "${PROVISIONED_RANDOM_ID}")
EOF
fi

# POV users are always admins
if [ "$POV_MODE" = true ]; then
  make_user_admin || { echo "Could not make ${SPA_USER} admin"; exit 1; }
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
# TLS not validated (disabled): curl -s -k -X POST \
curl -s -X POST \
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
  # TLS not validated (disabled): MONITOR_OPS_TEAM_ID=$(curl -s -k -X GET \
  MONITOR_OPS_TEAM_ID=$(curl -s -X GET \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}" \
  "${ACCOUNT_PROVISIONER_MONITOR_API_URL}/api/v3/teams?filter=product:SDC&offset=0&orderBy=name:asc" | jq -r '.data[] | select(.name == "Monitor Operations") | .id')
  if [ -z "$MONITOR_OPS_TEAM_ID" ]; then
      echo "Monitor Operations team not found"
      exit 1
  fi
  # Get the account ID
  echo "Monitor Operations team ID: $MONITOR_OPS_TEAM_ID"

  # TLS not validated (disabled): curl -s -k -X GET \
  curl -s -X GET \
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
          "role": "ROLE_TEAM_EDIT"
      }' "$WORK_DIR/monitor-operations-team.json" > "$WORK_DIR/monitor-operations-team.json.tmp"
  cp "$WORK_DIR/monitor-operations-team.json.tmp" "$WORK_DIR/monitor-operations-team.json"
  rm "$WORK_DIR/monitor-operations-team.json.tmp"


  # update Monitor Operations team with new user assigned
  # TLS not validated (disabled): curl -s -k -X PUT \
  curl -s -X PUT \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}" \
  -d @$WORK_DIR/monitor-operations-team.json \
  "${ACCOUNT_PROVISIONER_MONITOR_API_URL}"/api/teams/${MONITOR_OPS_TEAM_ID} \
  | jq > /dev/null
fi
