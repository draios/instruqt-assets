#!/usr/bin/env bash
###
# Sysdig Agent and cloud_infra deploy helper for Sysdig Training tracks.
#
# AUTHORS:
#   Sysdig Education Team <team-training@sysdig.com>
#
#   Current SaaS regions: https://docs.sysdig.com/en/administration/saas-regions-and-ip-ranges/
#
# NAMING CONVENTIONS:
#   - Variables shared with the install_with_*.sh scripts, the env-var
#     interface (DYNAMIC_*, TEST_*, USE_*) and the files in $WORK_DIR keep
#     their historical UPPER_CASE names.
#   - USE_*  : feature flags (true/false).
#   - SKIP_* : opt-out flags (true/false).
#   - Variables private to a function are `local` and lower_case.
###

trap '' 2 # Signal capture quit with Ctrl+C


###########################    GLOBAL CONSTANTS    ############################
BOLD='\e[1m'
CYAN='\e[36m'
RESET='\e[0m'

WORK_DIR="${WORK_DIR:-/opt/sysdig}"
TRACK_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
AGENT_CONF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"; cd ../sysdig-agent; pwd -P)
echo "TRACK_DIR: ${TRACK_DIR}"
echo "AGENT_CONF_DIR: ${AGENT_CONF_DIR}"

TITLE="Sysdig Agent installation"

# Region number shown in the menu (and used by TEST_REGION). Numbers are a
# contract with the account provisioner and the Instruqt invites: never renumber,
# only append.
REGION_LABELS=(
    [1]="US East (Virginia) - us1"
    [2]="US West AWS (Oregon) - us2"
    [3]="US West GCP (Dallas) - us4"
    [4]="European Union (Frankfurt) - eu1"
    [5]="AP Australia (Sydney) - au1"
    [6]="AP Cybereason (Sydney) - au1"
    [7]="On Premises - onprem"
    [8]="European Union (Stockholm) - eu2"
    [9]="Middle East (Dammam) - me2"
    [10]="AP South (Mumbai) - in1"
    [11]="AP Japan (Tokyo) - jp1"
)
REGION_MAX=11
REGION_ONPREM=7

# <app domain> <agent collector> <helm region id> <Secure UI path>
# us1 (legacy domains) and onprem (user provided) are handled in set_values().
# Helm region IDs must exist in the sysdig/shield chart (pinned in install_with_helm.sh);
# jp1 is not in that chart yet, so it is installed as 'custom'.
REGION_DATA=(
    [2]="us2.app.sysdig.com ingest-us2.app.sysdig.com us2 /secure"
    [3]="app.us4.sysdig.com ingest.us4.sysdig.com us4 /secure"
    [4]="eu1.app.sysdig.com ingest-eu1.app.sysdig.com eu1 /secure"
    [5]="app.au1.sysdig.com ingest.au1.sysdig.com au1 /secure"
    [6]="cybereason.app.au1.sysdig.com ingest.au1.sysdig.com au1 /"
    [8]="app.eu2.sysdig.com ingest.eu2.sysdig.com eu2 /secure"
    [9]="app.me2.sysdig.com ingest.me2.sysdig.com me2 /secure"
    [10]="app.in1.sysdig.com ingest.in1.sysdig.com in1 /secure"
    [11]="app.jp1.sysdig.com ingest.jp1.sysdig.com custom /secure"
)

##############################    GLOBAL VARS    ##############################
# Set by set_values()
MONITOR_URL=''
SECURE_URL=''
COLLECTOR_HOST=''
NIA_ENDPOINT=''
HELM_REGION_ID=''
MONITOR_API_ENDPOINT=''
SECURE_API_ENDPOINT=''
REGION_NAME=''

# On-prem backend (region 7), see resolve_onprem()
ONPREM_URL="${ONPREM_URL:-}"            # --on-prem <url>
ONPREM_COLLECTOR="${ONPREM_COLLECTOR:-}"  # --collector <host[:port]>

# Read by install_with_*.sh
WAIT_ENABLED=false
INSTALL_WITH="${INSTALL_WITH:-}"

# Flags set from the command line
SKIP_CLEANUP=false
SKIP_CHECKS=false
USE_PROVISIONER=false
USE_AGENT=false
USE_MONITOR_API=false
USE_SECURE_API=false
USE_CLOUD=false
USE_CLOUD_SCANNER=false
USE_KUBEADM=false
USE_RUNTIME_VM=false
USE_CURSES=false
USE_REGION_HOST=false   # track with a host (nginx managed by systemctl)
USE_REGION_CLOUD=false  # track with a cloud account container (nginx alone)

# Flags that can also be set from the environment (and are read by install_with_*.sh)
DYNAMIC_SETUP="${DYNAMIC_SETUP:-false}"
USE_PROMETHEUS="${USE_PROMETHEUS:-false}"
USE_KSPM="${USE_KSPM:-false}"
USE_NODE_ANALYZER="${USE_NODE_ANALYZER:-false}"
USE_RAPID_RESPONSE="${USE_RAPID_RESPONSE:-false}"
USE_RESPONSE_ACTIONS="${USE_RESPONSE_ACTIONS:-false}"
USE_ADMISSION_CONTROL="${USE_ADMISSION_CONTROL:-false}"
USE_ALL_FEATURES="${USE_ALL_FEATURES:-false}"

# Credentials for non-interactive runs (base64 encoded).
TEST_AGENT_ACCESS_KEY="${DYNAMIC_AGENT_ACCESS_KEY:-${TEST_AGENT_ACCESS_KEY:-}}"
TEST_MONITOR_API="${DYNAMIC_MONITOR_API:-${TEST_MONITOR_API:-}}"
TEST_SECURE_API="${DYNAMIC_SECURE_API:-${TEST_SECURE_API:-}}"
TEST_REGION="${TEST_REGION:-2}"

# On-prem overrides (region 7). All can be set via Instruqt invite env-var overrides.
#   DYNAMIC_MONITOR_API_URL / DYNAMIC_SECURE_API_URL  backend URL (the first one wins)
#   DYNAMIC_COLLECTOR_HOST                            collector, "host" or "host:port"
#                                                     (defaults to the backend host)
#   DYNAMIC_COLLECTOR_PORT                            collector port (defaults to 6443)
DYNAMIC_MONITOR_API_URL="${DYNAMIC_MONITOR_API_URL:-}"
DYNAMIC_SECURE_API_URL="${DYNAMIC_SECURE_API_URL:-}"
DYNAMIC_COLLECTOR_HOST="${DYNAMIC_COLLECTOR_HOST:-}"
DYNAMIC_COLLECTOR_PORT="${DYNAMIC_COLLECTOR_PORT:-6443}"

###############################    FUNCTIONS    ###############################
##
# Message to display when ran into an issue
##
function panic_msg () {
    echo
    echo "Some errors were detected configuring this lab."
    echo "To restart the config of the environment, reload the terminal window (top right corner of the lab)."
    echo
    echo "You can ask for help using Intercom or get in touch with us at team-training@sysdig.com"
    exit 1
}

##
# True when no human is typing: provisioned user, dynamic setup or Instruqt test user.
##
function is_noninteractive () {
    [[ ${USE_PROVISIONER} == true ]] || [[ ${DYNAMIC_SETUP} == true ]] || [[ ${INSTRUQT_USER_ID:-} == "testuser-"* ]]
}

##
# Define nginx.conf values to enable redirect
# to the Sysdig Region selected by the user
#
# This function applies different changes depending
# on the type of resources attached to a track:
#   - hosts for an agent installation (nginx managed by systemctl)
#   - container for cloud account (nginx process alone, no systemctl)
##
function configure_tab_redirect () {
    echo "Setting up Instruqt tab redirect to Sysdig Dashboard"
    local servers="http { "
    servers+="server { listen 8997; server_name localhost; rewrite ^/(.*)\$ ${MONITOR_URL}/\$1 redirect; } "
    servers+="server { listen 8998; server_name localhost; rewrite ^/(.*)\$ ${SECURE_URL}/\$1 redirect; } "

    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
    sed -i -e "s@http {@${servers}@g" /etc/nginx/nginx.conf

    if [ "$USE_REGION_HOST" = true ]
    then
        systemctl restart nginx
    fi

    if [ "$USE_REGION_CLOUD" = true ]
    then
        pkill -f nginx
        nginx
    fi

    touch "$WORK_DIR/region_setup_OK"
}

##
# Hostname of a URL or host[:port] value (protocol, port and path stripped).
##
function host_of () {
    local value=${1#*://}
    value=${value%%/*}
    echo "${value%%:*}"
}

##
# Port of a host[:port] value, or $2 when it has none.
##
function port_of () {
    local value=${1#*://}
    value=${value%%/*}
    if [[ $value == *:* ]]
    then
        echo "${value##*:}"
    else
        echo "$2"
    fi
}

##
# Ask for (or read from the environment) the on-prem backend URL and collector.
# Sets ONPREM_DOMAIN and ONPREM_COLLECTOR_HOST, and DYNAMIC_COLLECTOR_PORT.
#
#   URL:       --on-prem, DYNAMIC_MONITOR_API_URL, DYNAMIC_SECURE_API_URL or a prompt.
#   Collector: --collector, DYNAMIC_COLLECTOR_HOST or a prompt. Defaults to the URL host.
#   Port:      the one in the collector value, DYNAMIC_COLLECTOR_PORT or 6443.
#
# The API/UI URL is always https://<host> (443): a port in the URL is ignored,
# as it was historically used to carry the collector port.
##
function resolve_onprem () {
    local url=${ONPREM_URL:-${DYNAMIC_MONITOR_API_URL:-$DYNAMIC_SECURE_API_URL}}
    local collector=${ONPREM_COLLECTOR:-$DYNAMIC_COLLECTOR_HOST}

    if [[ -z $url ]]
    then
        if is_noninteractive
        then
            echo "ERROR: On-prem region requires --on-prem, DYNAMIC_MONITOR_API_URL or DYNAMIC_SECURE_API_URL."
            panic_msg
        fi
        read -p "   Sysdig on-prem URL (e.g. https://sysdig.example.com): " url
        [[ -n $url ]] || panic_msg
    fi
    ONPREM_DOMAIN=$(host_of "$url")

    if [[ -z $collector ]] && ! is_noninteractive
    then
        read -p "   Collector host[:port] (empty = ${ONPREM_DOMAIN}:${DYNAMIC_COLLECTOR_PORT}): " collector
    fi
    collector=${collector:-$ONPREM_DOMAIN}
    ONPREM_COLLECTOR_HOST=$(host_of "$collector")
    DYNAMIC_COLLECTOR_PORT=$(port_of "$collector" "$DYNAMIC_COLLECTOR_PORT")

    echo "On-prem domain: ${ONPREM_DOMAIN}"
    echo "On-prem collector: ${ONPREM_COLLECTOR_HOST}:${DYNAMIC_COLLECTOR_PORT}"
    # kept for tracks reading it (written by older versions of this script)
    echo "${ONPREM_DOMAIN}" > "$WORK_DIR/ON_PREM_ENDPOINT"
}

##
# Define URL and endpoints for the region number received.
#
# This is used to define the URL of the track-TABS, for API queries and define
# agent parameters like ${HELM_REGION_ID} (see REGION_DATA).
#
# Update REGION_LABELS/REGION_DATA when a new region is created.
# Docs: https://docs.sysdig.com/en/administration/saas-regions-and-ip-ranges
##
function set_values () {
    local region_number=$1
    local domain='' secure_path='/secure'

    case $region_number in
        "$REGION_ONPREM")
            resolve_onprem
            domain=$ONPREM_DOMAIN
            COLLECTOR_HOST=$ONPREM_COLLECTOR_HOST
            HELM_REGION_ID=custom
            ;;
        1)
            # us1 uses the legacy domains
            MONITOR_URL='https://app.sysdigcloud.com'
            SECURE_URL='https://secure.sysdig.com'
            COLLECTOR_HOST='collector.sysdigcloud.com'
            NIA_ENDPOINT='https://collector-static.sysdigcloud.com/internal/scanning/scanning-analysis-collector'
            HELM_REGION_ID=us1
            SECURE_API_ENDPOINT=$SECURE_URL
            ;;
        *)
            read -r domain COLLECTOR_HOST HELM_REGION_ID secure_path <<< "${REGION_DATA[region_number]}"
            ;;
    esac

    if [[ -n $domain ]]
    then
        MONITOR_URL="https://${domain}"
        SECURE_URL="${MONITOR_URL}${secure_path}"
        NIA_ENDPOINT="${MONITOR_URL}/internal/scanning/scanning-analysis-collector"
        SECURE_API_ENDPOINT=$MONITOR_URL
    fi
    MONITOR_API_ENDPOINT=$MONITOR_URL

    echo "${MONITOR_API_ENDPOINT}" > "$WORK_DIR/MONITOR_API_ENDPOINT"
    echo "${SECURE_API_ENDPOINT}" > "$WORK_DIR/SECURE_API_ENDPOINT"

    # If nginx is installed
    if command -v nginx >/dev/null; then
        configure_tab_redirect
    fi
}

##
# Prompt user to select agent collector (region).
##
function select_region () {
    local choice i dialog_items=()

    while true
    do
        if [[ "${USE_CURSES}" == false ]] || [[ "${DYNAMIC_SETUP}" == true ]]
        then
            echo
            echo "Sysdig SaaS Region"
            echo "==========================="
            echo
            echo "Check the docs if more info about regions is required to find what's yours:"
            echo "   https://docs.sysdig.com/en/administration/saas-regions-and-ip-ranges"
            echo
            echo "Please select your Sysdig SaaS account Region: "
            echo
            echo "   0) Abort install"
            for (( i=1; i<=REGION_MAX; i++ )); do
                echo "   $(printf '%2s' "$i")) ${REGION_LABELS[i]}"
            done
            echo

            if is_noninteractive
            then
                choice=${TEST_REGION}
                echo "Region number to use $choice"
                echo "   Instruqt test or provided Sysdig SaaS region will be used."
            else
                read -p "   Select Region (type number): " choice
            fi
        else
            dialog_items=()
            for (( i=1; i<=REGION_MAX; i++ )); do
                dialog_items+=("$i" "${REGION_LABELS[i]}")
            done
            choice=$(dialog --title "$TITLE" \
                            --menu "Select your Sysdig Agent region:" 20 60 11 \
                            "${dialog_items[@]}" \
                            3>&1 1>&2 2>&3 3>&-
                    ) || choice=0
        fi

        if [[ $choice == 0 ]]
        then
            echo "   Abort init.sh. Region not defined, agent not installed. This track will not work properly."
            exit 0
        fi

        if [[ $choice =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= REGION_MAX ))
        then
            choice=$(( 10#$choice ))
            break
        fi

        echo "${choice} is not a valid an option."
        # Retrying cannot help when the value comes from the environment.
        if is_noninteractive; then panic_msg; fi
    done

    REGION_NAME=${REGION_LABELS[choice]}
    echo -e "\n   ${REGION_NAME} selected.\n"
    set_values "$choice"
}

##
# Configure Sysdig API access for Monitor or Secure.
#
# Usage:
#   configure_api ${PRODUCT} ${PRODUCT_URL} ${PRODUCT_API_ENDPOINT}
#
#   PRODUCT := { SECURE | MONITOR }
##
function configure_api () {
    local product=$1
    local product_url=$2
    local api_endpoint=$3
    local ok_file="$WORK_DIR/user_data_${product}_API_OK"
    local test_token_var="TEST_${product}_API"
    local attempt=0 max_attempts=7 token

    echo "Configuring Sysdig $product API"

    if [ -f "$ok_file" ]
    then
        echo -e "  Sysdig ${product} API already configured.\n"
        return
    fi

    if [ "$USE_CURSES" = false ]
    then
        echo -e "  Visit ${BOLD}${CYAN}${product_url}/#/settings/user${RESET} to retrieve your Sysdig ${product} API Token."
    fi

    while [ ! -f "$ok_file" ] && [ $attempt -le $max_attempts ]
    do
        attempt=$(( attempt + 1 ))

        if is_noninteractive
        then
            token=$(echo -n "${!test_token_var:-}" | base64 --decode)
            echo "TEST_${product}_API_TOKEN=${token}"
        elif [ "$USE_CURSES" = false ]
        then
            read -p "  Insert here your Sysdig $product API Token: " token
        else
            token=$(dialog --title "$TITLE" \
                           --inputbox "Visit ${product_url}/#/settings/user to retrieve your Sysdig ${product} API Token.\n\n(You can use copy/paste with right click menu)\n\nInsert your Sysdig $product API Token:" 14 60 \
                           3>&1 1>&2 2>&3 3>&-
                   )
        fi

        # Test connection using /api/users/me — works for all roles including non-admin.
        # /api/alerts returns 403 for restricted roles even with a valid token.
        echo -n "  Testing connection to API on endpoint ${api_endpoint}... "
        # TLS not validated (disabled): if curl --insecure -sD - -o /dev/null -H "Authorization: Bearer ${token}" "${api_endpoint}/api/users/me" | grep '200' > /dev/null
        if curl -sD - -o /dev/null -H "Authorization: Bearer ${token}" "${api_endpoint}/api/users/me" | grep '200' > /dev/null
        then
            echo "  success"
            echo "${token}" > "$ok_file"
            export "SYSDIG_${product}_API_TOKEN=${token}"
        else
            echo "  failed"
        fi
        sleep 1
        echo
    done

    if [ ! -f "$ok_file" ]
    then
        echo "  Failed to connect to API Endpoint with selected Region and API Key(s)."
        panic_msg
    fi
}

##
# For envs where an agent is installed,
# selects the installation method depending on the environment.
##
function installation_method () {
    if [[ -z "$INSTALL_WITH" ]]
    then
        if command -v helm >/dev/null
        then
            INSTALL_WITH="helm"
        elif command -v docker >/dev/null
        then
            INSTALL_WITH="docker"
            export NIA_ENDPOINT
        else
            INSTALL_WITH="host"
        fi
    fi
}

##
# Deploy a Sysdig Agent with the installation method selected.
# Uses: CLUSTER_NAME, AGENT_ACCESS_KEY, COLLECTOR_HOST, HELM_REGION_ID,
#       SYSDIG_SECURE_API_TOKEN, SECURE_API_ENDPOINT
##
function install_agent () {
    if [[ "$INSTALL_WITH" == "helm" ]]
    then
        source "$TRACK_DIR/install_with_helm.sh" "$CLUSTER_NAME" "$AGENT_ACCESS_KEY" "$HELM_REGION_ID" "$SYSDIG_SECURE_API_TOKEN" "$COLLECTOR_HOST" "$SECURE_API_ENDPOINT"
    else
        source "$TRACK_DIR/install_with_${INSTALL_WITH}.sh" "$CLUSTER_NAME" "$AGENT_ACCESS_KEY" "$COLLECTOR_HOST"
    fi
}

##
# Print a line of the welcome message when a flag is enabled.
#
# Usage:
#   intro_item ${FLAG} ${MESSAGE}
##
function intro_item () {
    [[ "$1" == true ]] && echo "    - $2"
    return 0
}

##
# Display banner with welcome message.
##
function intro () {
    cat <<'EOF'
----------------------------------------------------------
   ____ __  __   ____   ___    ____  _____
  / __/ \ \/ /  / __/  / _ \  /  _/ / ___/
 _\ \    \  /  _\ \   / // / _/ /  / (_ /
/___/    /_/  /___/  /____/ /___/  \___/

 ______   ___    ___    ____   _  __   ____   _  __  _____
/_  __/  / _ \  / _ |  /  _/  / |/ /  /  _/  / |/ / / ___/
 / /    / , _/ / __ | _/ /   /    /  _/ /   /    / / (_ /
/_/    /_/|_| /_/ |_|/___/  /_/|_/  /___/  /_/|_/  \___/
----------------------------------------------------------

  Welcome! This script configures the lab environment.
  It will:
    - Set up your Sysdig region.
EOF

    intro_item "$USE_PROVISIONER"      "Provisions a user in Sysdig Saas account for this lab."
    intro_item "$USE_MONITOR_API"      "Set up the environment for Monitor API usage."
    intro_item "$USE_SECURE_API"       "Set up the environment for Secure API usage."
    intro_item "$USE_AGENT"            "Set up Instruqt tab with access to the Sysdig Dashboard."
    intro_item "$USE_AGENT"            "Deploy a Sysdig Agent."
    intro_item "$USE_NODE_ANALYZER"    "Enable the Agent Node Analyzer."
    intro_item "$USE_KSPM"             "Enable KSPM."
    intro_item "$USE_RAPID_RESPONSE"   "Enable Rapid Response."
    intro_item "$USE_RESPONSE_ACTIONS" "Enable Response Actions."
    intro_item "$USE_ALL_FEATURES"     "Enable all Sysdig Shield features."
    intro_item "$USE_PROMETHEUS"       "Enable the Agent Prometheus collector."
    intro_item "$USE_CLOUD"            "Set up Instruqt tab with access to the Sysdig Dashboard."
    intro_item "$USE_CLOUD"            "Enable CloudVision."
    intro_item "$USE_CLOUD_SCANNER"    "Deploys the Image Scanner for Cloud Registries."
    intro_item "$USE_KUBEADM"          "Customize Helm installer for kubeadm K8s cluster."
    intro_item "$USE_RUNTIME_VM"       "Deploy Runtime Scanner. Requires --node-analyzer."
    intro_item "$DYNAMIC_SETUP"        "Dynamic setup enabled."

    echo "  Follow the instructions below."
    echo
    echo "----------------------------------------------------------"
}


##
# Ask for Agent Key and deploy a Sysdig Agent.
##
function deploy_agent () {
    local deploy_date lab_id
    deploy_date=$(date -d '+2 hour' +"%F__%H_%M")
    lab_id=$(cat "$WORK_DIR/random_string_OK")
    if [ "$POV_MODE" = true ]
    then
        CLUSTER_NAME="${lab_id}_pov_cluster"
    else
        CLUSTER_NAME="${lab_id}_${deploy_date}"
    fi
    echo "${deploy_date}" > "$WORK_DIR/agent_deploy_date"
    echo "${CLUSTER_NAME}" > "$WORK_DIR/agent_cluster_id"

    # Expose Cluster ID as Instruqt var
    agent variable set SPA_CLUSTER "${CLUSTER_NAME}"

    echo "Configuring Sysdig Agent"

    if [ "$USE_CURSES" = false ]
    then
        echo -e "  Visit ${BOLD}${CYAN}${MONITOR_URL}/#/settings/agentInstallation${RESET} to retrieve your Sysdig Agent Key."
    fi

    if is_noninteractive
    then
        AGENT_ACCESS_KEY=$(echo -n "${TEST_AGENT_ACCESS_KEY}" | base64 --decode)
    elif [ "$USE_CURSES" = false ]
    then
        read -p "  Insert your Sysdig Agent Key: " AGENT_ACCESS_KEY
    else
        AGENT_ACCESS_KEY=$(dialog --title "$TITLE" \
                                  --inputbox "Visit ${MONITOR_URL}/#/settings/agentInstallation to retrieve your Sysdig Agent Key.\n\n(You can use copy/paste with right click menu)\n\nInsert your Sysdig Agent key:" 14 60 \
                                  3>&1 1>&2 2>&3 3>&-
                          )
    fi

    installation_method
    # in helm, we deploy by default the AC for k8s audit loging, we need the api
    if [[ "$INSTALL_WITH" == "helm" ]]
    then
        configure_api "SECURE" "${SECURE_URL}" "${SECURE_API_ENDPOINT}"
    fi

    echo -e "  The agent is being installed in the background.\n"
    install_agent
}

##
# Test if the Agent connected successfully to the collector endpoint.
##
function test_agent () {
    if [ "$USE_MONITOR_API" == true ] || [ "$USE_SECURE_API" == true ]
    then
        echo "Testing if Sysdig Agent is running correctly..."
    else
        echo "  Testing if Sysdig Agent is running correctly..."
    fi

    local attempt=0
    local max_attempts=10 # 0.5 minutes
    local connected_msg="Sending scraper version"
    local connected=false
    local found_collector="" agent_log

    while [ -z "${found_collector}" ] && [ "$connected" != true ] && [ $attempt -le $max_attempts ]
    do
        sleep 5
        case "$INSTALL_WITH" in
            helm)
                ## These checks aren't consistent
                #kubectl logs -l app=sysdig-agent -n sysdig-agent --tail=-1 | grep "cm_collector" | grep -q "Processing messages" && connected=true
                # The -l selector is not available in the current kubectl version installed
                kubectl rollout status daemonset/sysdig-agent-shield-host -n sysdig-agent -w --timeout=600s && connected=true
                agent_log=$(kubectl logs -l sysdig/component=host -n sysdig-agent || true)
                ;;
            docker)
                ### Todo: docker should check the existence of /opt/draios/logs/running <- leveraged by our kubernetes health check and is only created when the agent is officially connected to the backend
                agent_log=$(docker logs sysdig-agent 2>&1 || true)
                grep -q "${connected_msg}" <<< "$agent_log" && connected=true
                sleep 10     # Installation through docker takes more time
                ;;
            host)
                ### Todo: systemctl status sysdig-agent; if its running its connected and healthy.
                agent_log=$(cat /opt/draios/logs/draios.log || true)
                grep -q "${connected_msg}" <<< "$agent_log" && connected=true
                ;;
        esac
        found_collector=$(awk 'tolower($0) ~ /collector at host=/ {print $NF; exit}' <<< "$agent_log" | tr -d '[:space:]' || true)

        attempt=$(( attempt + 1 ))
    done

    if [ "$connected" = true ]
    then
        echo "  OK. Sysdig Agent successfully installed."
        touch "$WORK_DIR/user_data_AGENT_OK"
        echo "  Sysdig Agent cluster.name: $(cat "$WORK_DIR/agent_cluster_id")"
    else
        echo "  FAIL"
        echo "  Agent failed to connect to back-end. Check your Agent Key."
        # Dump install logs to help diagnose failures
        for log in "$WORK_DIR/helm_install.out" "$WORK_DIR/docker_install.out"; do
            if [ -f "$log" ]; then
                echo "--- $log ---"
                cat "$log"
            fi
        done
        panic_msg
    fi
}

##
# Checks if the track includes a cloud account
# and sets the CLOUD_ACCOUNT_ID variable with an identifier of the cloud account
# that will be used to deploy the required infra in the cloud provider selected
#
# More info about resources and variables used in this function:
#    -----------------------------------------------------------------------------
#    Instruqt can attach a burner cloud account with a track. It injects
#    credentials to use the account in the host or cloud_container. This
#    function checks if there's a cloud account in the track and in that case
#    it sets the requiered env vars to use it and deploy sysdig secure for cloud.
#
#    To learn more about it:
#    https://docs.instruqt.com/how-to-guides/manage-sandboxes/access-cloud-accounts
#    -----------------------------------------------------------------------------
#
# NOTE: this function do not support >1 cloud accounts attached to the track sandbox
#
##
function detect_cloud_account () {
    local account_var sa_key_var tenant_var sa_key

    if [ -n "${INSTRUQT_AWS_ACCOUNTS:-}" ]
    then
        CLOUD_PROVIDER=aws
        account_var=INSTRUQT_AWS_ACCOUNT_${INSTRUQT_AWS_ACCOUNTS}_ACCOUNT_ID
        CLOUD_ACCOUNT_ID=${!account_var}
    fi

    if [ -n "${INSTRUQT_GCP_PROJECTS:-}" ]
    then
        CLOUD_PROVIDER=gcp
        account_var=INSTRUQT_GCP_PROJECT_${INSTRUQT_GCP_PROJECTS}_PROJECT_ID
        CLOUD_ACCOUNT_ID=${!account_var}

        # terraform config to use the service account with role.owner permissions.
        # the user account provided by instruqt do not have org-level permissions and these
        # are required for the sysdig-cloud GCP installer
        sa_key_var=INSTRUQT_GCP_PROJECT_${INSTRUQT_GCP_PROJECTS}_SERVICE_ACCOUNT_KEY
        sa_key=${!sa_key_var}
        echo "$sa_key" | base64 -d > creds.json # credentials for the Service Account
        export TF_VAR_project=$CLOUD_ACCOUNT_ID
        grep -q "$CLOUD_ACCOUNT_ID" /root/.bashrc || echo "export TF_VAR_project=\"$CLOUD_ACCOUNT_ID\"" >> /root/.bashrc

        # set the path for terraform to use the service account credentials
        export GOOGLE_CREDENTIALS=$(pwd)/creds.json
        echo "export GOOGLE_CREDENTIALS=$GOOGLE_CREDENTIALS" >> /root/.bashrc
    fi

    if [ -n "${INSTRUQT_AZURE_SUBSCRIPTIONS:-}" ]
    then
        CLOUD_PROVIDER=azure
        account_var=INSTRUQT_AZURE_SUBSCRIPTION_${INSTRUQT_AZURE_SUBSCRIPTIONS}_SUBSCRIPTION_ID
        tenant_var=INSTRUQT_AZURE_SUBSCRIPTION_${INSTRUQT_AZURE_SUBSCRIPTIONS}_TENANT_ID
        AZURE_TENANT_ID=${!tenant_var}
        CLOUD_ACCOUNT_ID=${!account_var}
    fi

    if [ -z "${CLOUD_PROVIDER:-}" ]
    then
        echo "  FAIL"
        echo "  This track does not include a cloud account but it should."
        panic_msg
    fi
}

##
# Deploys the cloud connector.
##
function deploy_cloud_connector () {
    local deploy_date deploy_query
    deploy_date=$(date -d '+2 hour' +"%F__%H_%M")
    # a deployment date that matches the format and timezone of the date returned by sysdig API CloudProvidersLastSeen
    deploy_query=$(date +"%FT%H:%M:%S")
    echo "${deploy_date}" > "$WORK_DIR/cloud_connector_deploy_date"
    echo "${deploy_query}" > "$WORK_DIR/cloud_connector_deploy_query"

    echo "Configuring Sysdig CloudVision for $CLOUD_PROVIDER"

    # we are defining here some values (region) but in future we might want the user to choose its region
    # right now there's not a reason to select one or another
    case $CLOUD_PROVIDER in
        aws)   CLOUD_REGION="us-east-1" ;;
        gcp)   CLOUD_REGION="us-east1" ;;
        azure) CLOUD_REGION="foo" ;;
        *)     CLOUD_REGION="" ;;
    esac

    echo -e "  CloudVision is being installed in the background.\n"

    source "$TRACK_DIR/cloud/install_with_terraform.sh" "$CLOUD_PROVIDER" "$SYSDIG_SECURE_API_TOKEN" "$SECURE_API_ENDPOINT" "$CLOUD_REGION" "$CLOUD_ACCOUNT_ID"
}

##
# Test if the Cloud account is connected successfully.
##
function test_cloud_connector () {
    local attempt=0
    local max_attempts=36 # 6 minutes
    local connected=false
    local accounts_url="${SECURE_API_ENDPOINT}/api/cloudauth/v1/accounts"
    local lab_id internal_id account_alias

    lab_id=$(cat "$WORK_DIR/random_string_OK")

    sysdig_get () {
        curl -s -H "Authorization: Bearer $SYSDIG_SECURE_API_TOKEN" -H 'Content-Type: application/json' "$1"
    }

    internal_id=$(sysdig_get "$accounts_url" | jq -r '.accounts[] | select(.providerId == '"${CLOUD_ACCOUNT_ID}"') | .id')

    echo "    Testing if the cloud account is connected... (ID=${CLOUD_ACCOUNT_ID})"

    while [ "$connected" != true ] && [ $attempt -le $max_attempts ]
    do
        # validate cloud account
        sysdig_get "${accounts_url}/${internal_id}/validate"

        sleep 10

        # find account via alias
        account_alias=$(sysdig_get "$accounts_url" | jq -r '.accounts[] | select(.providerId == '"${CLOUD_ACCOUNT_ID}"') | .providerAlias')

        if [[ "${lab_id}" =~ "${account_alias}" ]]
        then
            connected=true
            break
        fi

        attempt=$(( attempt + 1 ))
    done

    unset -f sysdig_get

    if [ "$connected" = true ]
    then
        echo "  Cloud Account Integration configured."
        touch "$WORK_DIR/user_data_CLOUDVISION_OK"
    else
        echo "  FAIL"
        echo "  Cloud Account Integration installation went wrong. Use the provided channels to report this issue."
        panic_msg
    fi
}

##
# Delete files only needed while running the script.
##
function clean_setup () {
    local entry flag name

    # <enabled flag>:<name of its health-check marker file>
    for entry in USE_AGENT:AGENT USE_MONITOR_API:MONITOR_API USE_SECURE_API:SECURE_API
    do
        flag=${entry%%:*}
        name=${entry##*:}
        if [ "${!flag}" == true ]
        then
            if [ -f "$WORK_DIR/user_data_${name}_OK" ]
            then
                rm "$WORK_DIR/user_data_${name}_OK"
            else
                panic_msg
            fi
        fi
    done

    if [ -d "$TRACK_DIR" ]
    then
        # we used to remove these files, but they are useful for debugging.
        # Also, the terraform state file is good to keep it in case we need to destroy the assets
        # In most cases we don't care about this, as Instruqts manages the cleanup of the envs.
        mv "$TRACK_DIR/" /tmp/
        test -f /root/creds.json && mv /root/creds.json /tmp/
        sed -i '/init.sh/d' /root/.profile  # removes the script from .profile so it is not executed in new challenges
        touch "$WORK_DIR/user_data_OK" # flag environment configured with user data
    else
        panic_msg
    fi
}

##
# Show help and script usage
##
function help () {
    cat <<EOF

USAGE:

  $(basename "$0") [OPTIONS...]

Environment start up script. It can be used to:
- deploy a Sysdig Agent
- deploy Sysdig Secure for Cloud (AWS, GCP, Azure)
- and/or set up some environment variables.

Review the options below to learn what's available.

WARNING: This script is meant to be used in training materials.
Do NOT use it in production.


OPTIONS:

  --skip-cleanup              Skip script setup clean-up actions.
  --provision-user            Creates user in Sysdig Saas Training account for use in this lab.
  --dynamic-setup             Do not use the user provisioner, use the runtime parameters.
  --wait                      Make the Helm installation wait until the agent is ready.
  -a, --agent                 Deploy a Sysdig Agent.
  -A, --all-features          Enable every Sysdig Shield feature (admission control in enforce
                              mode, posture, vulnerability management, detections, investigations,
                              response actions). Use with -a/--agent. Works for SaaS and on-prem.
  -b, --rapid-response        Enable Rapid Response
  -c, --cloud                 Set up environment for Sysdig Secure for Cloud.
  -h, --help                  Show this help.
  -j, --admission-controller  Enable Admission Controller. Use with -a/--agent.
  -k, --kspm                  Enable KSPM. Use with -a/--agent.
  -m, --monitor               Set up environment for Monitor API usage.
  -n, --node-analyzer         Enable Node Analyzer. Use with -a/--agent.
  -p, --prometheus            Enable Prometheus. Use with -a/--agent.
  -q, --region-cloud          Set up environment with user's Sysdig Region for cloud track with a cloud account.
  -r, --region                Set up environment with user's Sysdig Region for a track with a host.
  -s, --secure                Set up environment for Secure API usage.
  -v, --vuln-management       Enable Image Scanning with Sysdig Secure for Cloud. Use with -c/--cloud.
  -x, --use-curses            Use ncurses dialog menus instead of CLI.
  -8, --kube-adm              Customize installer for kubeadm k8s cluster
  --on-prem <url>             On-prem backend URL (region 7), e.g. https://sysdig.example.com
      --collector <host[:port]>  On-prem agent collector (region 7). Defaults to the backend host, port 6443.
      --response-actions      Enable Response Actions. Use with -a/--agent.
      --runtime-vm            Enable VM Runtime Scanner. Use with --node-analyzer.
      --no-check              Remove agent and cloud connector post install health check.


ENVIRONMENT VARIABLES:

  INSTALL_WITH                Sets preferred installation method. Available
                              options are 'helm', 'docker' and 'host'. If not
                              set, it will default to what's available in your,
                              checking first for 'helm', then 'docker', and
                              finally 'host'.

  HELM_OPTS                   Additional options for Helm installation.

  DOCKER_OPTS                 Additional options for Docker installation.

  HOST_OPTS                   Additional options for Host installation.

  DYNAMIC_SETUP               Set to 'true' to skip interactive prompts and use
                              the TEST_* / DYNAMIC_* env vars below instead.
                              Can be set via Instruqt invite env-var overrides.

  DYNAMIC_AGENT_ACCESS_KEY    Base64-encoded Sysdig Agent access key.
                              Overrides TEST_AGENT_ACCESS_KEY.

  DYNAMIC_MONITOR_API         Base64-encoded Sysdig Monitor API token.
                              Overrides TEST_MONITOR_API.

  DYNAMIC_SECURE_API          Base64-encoded Sysdig Secure API token.
                              Overrides TEST_SECURE_API.

  TEST_REGION                 Region number used in non-interactive/dynamic mode.
                              Defaults to 2 (US West AWS - us2). Values:
                                1  US East (Virginia) - us1
                                2  US West AWS (Oregon) - us2
                                3  US West GCP (Dallas) - us4
                                4  European Union (Frankfurt) - eu1
                                5  AP Australia (Sydney) - au1
                                6  AP Cybereason (Sydney) - au1
                                7  On Premises (requires DYNAMIC_MONITOR_API_URL
                                   or DYNAMIC_SECURE_API_URL)
                                8  European Union (Stockholm) - eu2
                                9  Middle East (Dammam) - me2
                                10 AP South (Mumbai) - in1
                                11 AP Japan (Tokyo) - jp1

  DYNAMIC_MONITOR_API_URL     Base URL of the on-prem Sysdig backend
                              (e.g. https://sysdig.corp.example.com).
                              Required when TEST_REGION=7 in dynamic/test mode.
                              Takes precedence over DYNAMIC_SECURE_API_URL.

  DYNAMIC_SECURE_API_URL      Base URL of the on-prem Sysdig Secure backend.
                              Fallback for DYNAMIC_MONITOR_API_URL when TEST_REGION=7.

  DYNAMIC_COLLECTOR_HOST      On-prem agent collector, "host" or "host:port".
                              Defaults to the host of the backend URL.

  DYNAMIC_COLLECTOR_PORT      On-prem agent collector port. Defaults to 6443.

  POV_MODE                    'true' (default in this branch) names the provisioned user
                              <adjective>_<noun>+pov@sysdig.com (admin, Secure only) and the
                              cluster <adjective>_<noun>_pov_cluster. 'false' restores the
                              training naming (<adjective>_<noun>_<salt>, student user).

EOF
}


##
# Check and consume script flags.
##
function check_flags () {
    while [ ! $# -eq 0 ]
    do
        case "$1" in
            --wait)
                export WAIT_ENABLED=true
                ;;
            --on-prem) # on-prem backend URL
                shift
                ONPREM_URL=$1
                echo "On Premise backend endpoint: $ONPREM_URL"
                ;;
            --collector) # on-prem collector, host[:port]
                shift
                ONPREM_COLLECTOR=$1
                ;;
            --skip-cleanup)
                SKIP_CLEANUP=true
                ;;
            --provision-user)
                USE_PROVISIONER=true
                ;;
            --dynamic-setup)
                DYNAMIC_SETUP=true
                ;;
            --agent | -a)
                USE_AGENT=true
                USE_REGION_HOST=true
                ;;
            --region | -r)
                USE_REGION_HOST=true
                ;;
            --cloud | -c)
                USE_CLOUD=true
                USE_REGION_CLOUD=true
                USE_SECURE_API=true
                ;;
            --region-cloud | -q)
                USE_REGION_CLOUD=true
                ;;
            --monitor | -m)
                USE_MONITOR_API=true
                ;;
            --secure | -s)
                USE_SECURE_API=true
                ;;
            --node-analyzer | -n)
                export USE_NODE_ANALYZER=true
                ;;
            --kspm | -k)
                export USE_KSPM=true
                ;;
            --prometheus | -p)
                export USE_PROMETHEUS=true
                ;;
            --rapid-response | -b)
                export USE_RAPID_RESPONSE=true
                ;;
            --response-actions)
                export USE_RESPONSE_ACTIONS=true
                ;;
            --all-features | -A)
                # everything in the reference shield values.yaml (see install_with_helm.sh)
                export USE_ALL_FEATURES=true
                export USE_NODE_ANALYZER=true
                export USE_KSPM=true
                export USE_ADMISSION_CONTROL=true
                export USE_RESPONSE_ACTIONS=true
                ;;
            --admission-controller | -j)
                export USE_ADMISSION_CONTROL=true
                ;;
            --vuln-management | -v)
                export USE_CLOUD_SCANNER=true
                ;;
            --use-curses | -x)
                export USE_CURSES=true
                ;;
            --kube-adm | -8)
                export USE_KUBEADM=true
                ;;
            --runtime-vm)
                export USE_RUNTIME_VM=true
                ;;
            --no-check)
                export SKIP_CHECKS=true
                ;;
            --help | -h)
                help
                exit 0
                ;;
            *)
                echo "Unkown argument: $1"
                help
                exit 1
                ;;
        esac
        shift
    done

    if [ "$USE_AGENT" != true ] && {
           [ "$USE_ALL_FEATURES" = true ] || [ "$USE_NODE_ANALYZER" = true ] || [ "$USE_PROMETHEUS" = true ] || [ "$USE_RUNTIME_VM" = true ] ||
           [ "$USE_RAPID_RESPONSE" = true ] || [ "$USE_KUBEADM" = true ]
       }
    then
        echo "ERROR: Options only available with -a/--agent."
        exit 1
    fi
}

##
# Use the credentials of the account created by the user provisioner.
##
function use_provisioned_creds () {
    local api_token
    api_token=$(jq --raw-output .token.key "$WORK_DIR/account.json")

    TEST_AGENT_ACCESS_KEY=$(base64 < "$WORK_DIR/ACCOUNT_PROVISIONER_AGENT_ACCESS_KEY")
    TEST_MONITOR_API=$(echo "$api_token" | base64)
    TEST_SECURE_API=$TEST_MONITOR_API
    TEST_REGION=$(cat "$WORK_DIR/ACCOUNT_PROVISIONER_REGION")

    echo
    echo "----------------------------------------------------------"
    echo "- A Sysdig SaaS account has been provisioned with this lab"
    echo "----------------------------------------------------------"
    echo
    echo "  These are your credentials (also available in the instructions in the right):"
    echo "  User: $(cat "$WORK_DIR/ACCOUNT_PROVISIONED_USER")"
    echo "  Password: $(cat "$WORK_DIR/ACCOUNT_PROVISIONED_PASS")"
    echo "  Region: use the tab in this lab to access your Sysdig's UI"
    echo
    echo
}

##
# Execute setup.
##
function setup () {
    mkdir -p "$WORK_DIR/"

    check_flags "$@"

    if [ "${USE_CURSES}" = false ]
    then
        intro
    fi

    source "$TRACK_DIR/lab_random_string_id.sh"

    if [ "${USE_PROVISIONER}" = true ]
    then
        use_provisioned_creds
    fi

    if [ "$USE_REGION_HOST" = true ] || [ "$USE_REGION_CLOUD" = true ]
    then
        select_region
    fi

    if [ "$USE_AGENT" = true ]
    then
        deploy_agent
    fi

    if [ "$USE_MONITOR_API" = true ]
    then
        configure_api "MONITOR" "${MONITOR_URL}" "${MONITOR_API_ENDPOINT}"
    fi

    if [ "$USE_SECURE_API" = true ]
    then
        configure_api "SECURE" "${SECURE_URL}" "${SECURE_API_ENDPOINT}"
    fi

    if [ "$USE_AGENT" = true ] && [ "$SKIP_CHECKS" = false ]
    then
        test_agent
    fi

    if [ "$USE_CLOUD" = true ]
    then
        # we can't run `detect_cloud_account` and `deploy_cloud_connector`
        # before `configure_api` because they use data set within `configure_api`
        detect_cloud_account
        deploy_cloud_connector
        if [ "$SKIP_CHECKS" = false ]
        then
            test_cloud_connector
        fi
    fi

    if [ "$SKIP_CLEANUP" = false ]
    then
        clean_setup
    fi
}

################################    SCRIPT    #################################
setup "$@"
