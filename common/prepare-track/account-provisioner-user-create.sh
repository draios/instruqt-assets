#!/bin/bash
##
# User provisioner, creates a user in a general training Sysdig account
# so the user does not have to use its own.
##

set -euxo pipefail

if [ $# -ne 6 ]; then
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
mkdir -p "$WORK_DIR"
mkdir -p "$TRACK_DIR"

# API Base URL for Platform (removing potential 'app' prefix)
PLATFORM_API_URL=$(echo "${ACCOUNT_PROVISIONER_MONITOR_API_URL}" | sed 's/app\./api./')

# Decode the base64 credentials
ACCOUNT_PROVISIONER_MONITOR_API_TOKEN=$(echo -n "${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}" | base64 --decode)
ACCOUNT_PROVISIONER_SECURE_API_TOKEN=$(echo -n "${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}" | base64 --decode)
ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY=$(echo -n "${ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY}" | base64 --decode)

# persist values
echo "${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}" > "$WORK_DIR/ACCOUNT_PROVISIONER_MONITOR_API_TOKEN"
echo "${ACCOUNT_PROVISIONER_MONITOR_API_URL}" > "$WORK_DIR/ACCOUNT_PROVISIONER_MONITOR_API_URL"
echo "${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}" > "$WORK_DIR/ACCOUNT_PROVISIONER_SECURE_API_TOKEN"
echo "${ACCOUNT_PROVISIONER_SECURE_API_URL}" > "$WORK_DIR/ACCOUNT_PROVISIONER_SECURE_API_URL"
echo "${ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY}" > "$WORK_DIR/ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY"
echo "${ACCOUNT_PROVISIONER_REGION_NUMBER}" > "$WORK_DIR/ACCOUNT_PROVISIONER_REGION"

source "$TRACK_DIR/lab_random_string_id.sh"

function provsion_user(){
  # create user in parent account using platform v1 API
  curl -s -k -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $1" \
  --data-binary '{
  "email": "'"${SPA_USER}"'",
  "firstName": "Id:",
  "lastName": "'"${SPA_USER}"'",
  "isAdmin": false,
  "bypassSsoEnforcement": false,
  "products": [
    "secure",
    "monitor"
  ]
  }' \
  "${PLATFORM_API_URL}/platform/v1/users" \
  | jq > "$WORK_DIR/account.json"
}

# define new user creds
SPA_PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16 ; echo '')
echo "${SPA_PASS}" > "$WORK_DIR/ACCOUNT_PROVISIONED_PASS"
agent variable set SPA_PASS "${SPA_PASS}"

SPA_USER=$(cat "$WORK_DIR/ACCOUNT_PROVISIONED_USER")
agent variable set SPA_USER "${SPA_USER}"

if [ "$DYNAMIC_PROVISIONER_MONITOR_ONLY" == "true" ]; then
  agent variable set SPA_MONITOR_API_TOKEN "${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}"
  agent variable set SPA_MONITOR_API_URL "${ACCOUNT_PROVISIONER_MONITOR_API_URL}"
else
  agent variable set SPA_SECURE_API_TOKEN "${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}"
  agent variable set SPA_MONITOR_API_TOKEN "${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}"
  agent variable set SPA_SECURE_API_URL "${ACCOUNT_PROVISIONER_SECURE_API_URL}"
  agent variable set SPA_MONITOR_API_URL "${ACCOUNT_PROVISIONER_MONITOR_API_URL}"
fi

PROVISIONED_RANDOM_ID=$(cat "$WORK_DIR/random_string_OK")
agent variable set PROVISIONED_RANDOM_ID "${PROVISIONED_RANDOM_ID}"

# Profile persistence
if [ -n "${PROVISIONED_RANDOM_ID:-}" ]; then
  export PROVISIONED_RANDOM_ID
  cat <<EOF >/etc/profile.d/provisioned_random_id.sh
export PROVISIONED_RANDOM_ID=$(printf '%q\n' "${PROVISIONED_RANDOM_ID}")
EOF
fi

# Provision User
if [ "$DYNAMIC_PROVISIONER_MONITOR_ONLY" == "true" ]; then
    provsion_user "${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}"
else
    provsion_user "${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}"
fi

touch "$WORK_DIR/user_provisioned_COMPLETED"

# Get user info
# Note: The platform API returns the user object directly, not wrapped in a 'user' key
SPA_USER_ID=$(jq '.id' "$WORK_DIR/account.json")

# Disable onboarding questionnaire
# (Left as is using the old endpoint as requested)
curl -s -k -X POST \
-H "Content-Type: application/json" \
-H "Authorization: Bearer ${ACCOUNT_PROVISIONER_SECURE_API_TOKEN}" \
--data-binary @- \
"${ACCOUNT_PROVISIONER_SECURE_API_URL}/api/secure/onboarding/v2/userProfile/questionnaire?userId=${SPA_USER_ID}" <<EOF > /dev/null
[
  {"id": "additionalEnvironments", "displayQuestion": "Q", "choices": []},
  {"id": "iacManifests", "displayQuestion": "Q", "choices": []},
  {"id": "cicdTool", "displayQuestion": "Q", "choices": []},
  {"id": "notificationChannels", "displayQuestion": "Q", "choices": []}
]
EOF

# Team assignment (Monitor)
if [ "$DYNAMIC_PROVISIONER_SECURE_ONLY" != "true" ]; then
  # 1. Find Monitor Operations Team ID
  MONITOR_OPS_TEAM_ID=$(curl -s -k -X GET \
    -H "Authorization: Bearer ${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}" \
    "${PLATFORM_API_URL}/platform/v1/teams?filter=product:monitor&offset=0&orderBy=name:asc" \
    | jq -r '.data[] | select(.name == "Monitor Operations") | .id')

  if [ -z "$MONITOR_OPS_TEAM_ID" ] || [ "$MONITOR_OPS_TEAM_ID" == "null" ]; then
      echo "Monitor Operations team not found"
      exit 1
  fi

  # 2. Find "Advanced with Sage Access" Role ID
  SAGE_ROLE_ID=$(curl -s -k -X GET \
    -H "Authorization: Bearer ${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}" \
    "${PLATFORM_API_URL}/platform/v1/roles" \
    | jq -r '.data[] | select(.name == "Advanced with Sage Access") | .id')

  # 3. Determine assignment payload
  if [ -n "$SAGE_ROLE_ID" ] && [ "$SAGE_ROLE_ID" != "null" ]; then
      ROLE_PAYLOAD='{"customTeamRoleId": '$SAGE_ROLE_ID'}'
      echo "Using custom role ID: $SAGE_ROLE_ID"
  else
      ROLE_PAYLOAD='{"standardTeamRole": "ROLE_TEAM_EDIT"}'
      echo "Custom role not found, using fallback: ROLE_TEAM_EDIT"
  fi

  # 4. Assign user to team with the correct role using Platform API
  curl -s -k -X PUT \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ACCOUNT_PROVISIONER_MONITOR_API_TOKEN}" \
    -d "$ROLE_PAYLOAD" \
    "${PLATFORM_API_URL}/platform/v1/teams/${MONITOR_OPS_TEAM_ID}/users/${SPA_USER_ID}" \
    | jq > /dev/null
fi
