#!/usr/bin/env bash
###
# Sysdig Agent and cloud_infra deploy helper for Sysdig Training tracks.
#
# AUTHORS:
#   Sysdig Education Team <team-training@sysdig.com>
#
#   Current SaaS regions: https://docs.sysdig.com/en/docs/administration/saas-regions-and-ip-ranges/
###

trap '' 2 # Signal capture quit with Ctrl+C


###########################    GLOBAL CONSTANTS    ############################
F_BOLD='\e[1m'
F_RED='\x1B[31m'
F_CYAN='\e[36m'
F_CLEAR='\e[0m'

WORK_DIR=/opt/sysdig
TRACK_DIR=/root/prepare-track
AGENT_CONF_DIR=/root/sysdig-agent


##############################    GLOBAL VARS    ##############################
INSTALL_WITH=''
MONITOR_URL=''
SECURE_URL=''
AGENT_COLLECTOR=''
NIA_ENDPOINT=''

USE_AGENT=false
USE_MONITOR_API=false
USE_SECURE_API=false
USE_NODE_ANALYZER=false
USE_NODE_IMAGE_ANALYZER=false
USE_PROMETHEUS=false
USE_CLOUD=false
USE_CLOUD_SCAN_ENGINE=false
USE_REGION_CLOUD=false
USE_AGENT_REGION=false

##############################    GLOBAL VARS    ##############################
TEST_AGENT_ACCESS_KEY=[REDACTED]
TEST_MONITOR_API=[REDACTED]
TEST_SECURE_API=[REDACTED]
TEST_REGION=2

###############################    FUNCTIONS    ###############################
##
# Message to display when ran into an issue
##
function panic_msg () {
    echo
    echo "Some errors were detected configuring this lab. Please, run again this script with:"
    echo "   /usr/bin/bash $TRACK_DIR/init.sh"
    echo
    echo "You can ask for help using Intercom or get in touch with us at team-training@sysdig.com"
    exit 1
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
function config_sysdig_tab_redirect () {
    OLD_STRING="http {"
    NEW_STRING="http {     server {         listen 8997;         server_name localhost;         rewrite ^/(.*)$ $MONITOR_URL/\$1 redirect;     }     server {         listen 8998;         server_name localhost;         rewrite ^/(.*)$ $SECURE_URL/\$1 redirect;     } "

    sed -i -e "s@${OLD_STRING}@${NEW_STRING}@g" /etc/nginx/nginx.conf

    if [ "$USE_AGENT_REGION" = true ]
    then
        systemctl restart nginx
    fi

    if [ "$USE_CLOUD_REGION" = true ]
    then
        pkill -f nginx
        nginx
    fi
}

##
# Define URL and endpoints for the selected region.
#
# This is used to define the URL of the track-TABS, for API queries and define
# agent parameters.
# 
# Update when a new region is created.
##
function set_values () {
    REGION=$1

    case $REGION in
        *"AWS US East"*)
            MONITOR_URL='https://app.sysdigcloud.com'
            SECURE_URL='https://secure.sysdig.com'
            AGENT_COLLECTOR='collector.sysdigcloud.com'
            NIA_ENDPOINT='https://collector-static.sysdigcloud.com/internal/scanning/scanning-analysis-collector'
            ;;

        *"AWS US West"*)
            DOMAIN='us2.app.sysdig.com'
            MONITOR_URL='https://'$DOMAIN
            SECURE_URL=$MONITOR_URL'/secure'
            AGENT_COLLECTOR='ingest-'$DOMAIN
            NIA_ENDPOINT=$MONITOR_URL'/internal/scanning/scanning-analysis-collector'
            ;;
        
        *"EMEA"*)
            DOMAIN='eu1.app.sysdig.com'
            MONITOR_URL='https://'$DOMAIN
            SECURE_URL=$MONITOR_URL'/secure'
            AGENT_COLLECTOR='ingest-'$DOMAIN
            NIA_ENDPOINT=$MONITOR_URL'/internal/scanning/scanning-analysis-collector'
            ;;

        *"Pacific"*)
            DOMAIN='app.au1.sysdig.com'
            MONITOR_URL='https://'$DOMAIN
            SECURE_URL=$MONITOR_URL'/secure'
            AGENT_COLLECTOR='ingest.au1.sysdig.com'
            NIA_ENDPOINT=$MONITOR_URL'/internal/scanning/scanning-analysis-collector'
            ;;
        
        *) # Default to GCP US West
            DOMAIN='app.us4.sysdig.com'
            MONITOR_URL='https://'$DOMAIN
            SECURE_URL=$MONITOR_URL'/secure'
            AGENT_COLLECTOR='ingest.us4.sysdig.com'
            NIA_ENDPOINT=$MONITOR_URL'/internal/scanning/scanning-analysis-collector'
            ;;
    esac

    MONITOR_API_ENDPOINT=$MONITOR_URL
    SECURE_API_ENDPOINT=$MONITOR_URL
    PROMETHEUS_ENDPOINT=$MONITOR_URL'/prometheus'

    config_sysdig_tab_redirect
}

##
# Prompt user to select agent collector (region).
##
function select_region () {
    echo
    echo "Please select one of the existing SaaS Regions: "
    echo "   0) Abort install"
    echo "   1) GCP US West (default)"
    echo "   2) AWS US East"
    echo "   3) AWS US West"
    echo "   4) EMEA"
    echo "   5) Pacific"

    if [[ ${INSTRUQT_USER_ID} == "testuser-"* ]]; 
    then
        REGION_N=${TEST_REGION}
    else
        read -p "   Select Region (type number): "  REGION_N; 
    fi

    case $REGION_N in
        0)
            echo "   Abort init.sh. Region not defined, agent not installed. This track will not work properly."
            exit 0
            ;;
        1)
            REGION="GCP US West (default)"
            ;;
        2)
            REGION="AWS US East"
            ;;
        3)
            REGION="AWS US West"
            ;;
        4)
            REGION="EMEA"
            ;;
        5)
            REGION="Pacific"
            ;;
        *)
            echo "${REGION_N} is not a valid an option."
            select_region
            ;;
    esac

    #based on selected region, values are defined
    echo -e "\n   ${REGION} selected.\n"
    set_values "$REGION"
}

##
# Configure Sysdig API access for Monitor or Secure.
# 
# Usage:
#   configure_API ${PRODUCT} ${PRODUCT_URL} ${PRODUCT_API_ENDPOINT}
#
#   PRODUCT := { SECURE | MONITOR }
##
function configure_API () {

    PRODUCT=$1
    PRODUCT_URL=$2
    PRODUCT_API_ENDPOINT=$3

    echo "Configuring Sysdig $PRODUCT API"

    if [ -f $WORK_DIR/user_data_${PRODUCT}_API_OK ]
    then
      echo -e "  Sysdig ${PRODUCT} API already configured.\n"
      return
    fi

    echo -e "  Visit ${F_BOLD}${F_CYAN}${PRODUCT_URL}/#/settings/user${F_CLEAR} to retrieve your Sysdig ${PRODUCT} API Token."
    varname=${PRODUCT}_API_KEY

    attempt=0
    MAX_ATTEMPTS=7

    while [ ! -f $WORK_DIR/user_data_${PRODUCT}_API_OK ] && [ $attempt -le $MAX_ATTEMPTS ]
    do
        attempt=$(( $attempt + 1 ))

        if [[ ${INSTRUQT_USER_ID} == "testuser-"* ]]; 
        then
            if [[ ${PRODUCT} == "MONITOR" ]];
            then
                API_TOKEN=$(echo -n ${TEST_MONITOR_API} | base64 --decode)
            else #SECURE
                API_TOKEN=$(echo -n ${TEST_SECURE_API} | base64 --decode)
            fi
        else
            read -p "  Insert here your Sysdig $PRODUCT API Token: "  API_TOKEN;
        fi

        # Test connection
        echo -n "  Testing connection to API... "
        curl -sD - -o /dev/null -H "Authorization: Bearer ${API_TOKEN}" "${PRODUCT_API_ENDPOINT}/api/alerts" | grep 'HTTP/2 200' &> /dev/null
        
        if [ $? -eq 0 ]
        then
            echo "  OK"
            echo "${API_TOKEN}" > $WORK_DIR/user_data_${PRODUCT}_API_OK
            export SYSDIG_${PRODUCT}_API_TOKEN="${API_TOKEN}"
        else
            echo "  FAIL"
            echo "  Failed to connect to API Endpoint with selected Region and API Key(s)."
            panic_msg
        fi
        echo
    done
}

##
# For envs where an agent is installed,
# selects the installation method depending on the environment.
##
function installation_method () {
    if [[ -z "$INSTALL_WITH" ]]
    then
        if [ `which helm` ]
        then
            INSTALL_WITH="helm"
        elif [ `which docker` ]
        then
            INSTALL_WITH="docker"
            export NIA_ENDPOINT
        else
            INSTALL_WITH="host"
        fi
    fi
}

##
# Deploy a Sysdig Agent.
#
# Usage:
#   install_agent ${CLUSTER_NAME} ${ACCESS_KEY} ${COLLECTOR}
##
function install_agent () {

    CLUSTER_NAME=$1
    ACCESS_KEY=$2
    COLLECTOR=$3

    installation_method

    source $TRACK_DIR/install_with_${INSTALL_WITH}.sh $CLUSTER_NAME $ACCESS_KEY $COLLECTOR
}

##
# Display banner with welcome message.
##
function intro () {
    echo "----------------------------------------------------------"
    echo "   ____ __  __   ____   ___    ____  _____                "
    echo "  / __/ \ \/ /  / __/  / _ \  /  _/ / ___/                "
    echo " _\ \    \  /  _\ \   / // / _/ /  / (_ /                 "
    echo "/___/    /_/  /___/  /____/ /___/  \___/                  "
    echo "                                                          "
    echo " ______   ___    ___    ____   _  __   ____   _  __  _____"
    echo "/_  __/  / _ \  / _ |  /  _/  / |/ /  /  _/  / |/ / / ___/"
    echo " / /    / , _/ / __ | _/ /   /    /  _/ /   /    / / (_ / "
    echo "/_/    /_/|_| /_/ |_|/___/  /_/|_/  /___/  /_/|_/  \___/  "
    echo "----------------------------------------------------------"
    echo
    echo "  Welcome! This script configures the lab environment."
    echo "  It will:"

    echo "    - Set up your Sysdig region."

    if [ "$USE_MONITOR_API" == true ]; then
      echo "    - Set up the environment for Monitor API usage."
    fi

    if [ "$USE_SECURE_API" == true ]; then
      echo "    - Set up the environment for Secure API usage."
    fi

    if [ "$USE_AGENT" == true ]; then
      echo "    - Set up Instruqt tab with access to the Sysdig Dashboard."
      echo "    - Deploy a Sysdig Agent."
    fi

    if [ "$USE_NODE_ANALYZER" == true ]; then
      echo "    - Enable the Agent Node Analyzer."
    fi

    if [ "$USE_NODE_IMAGE_ANALYZER" == true ]; then
      echo "    - Enable the Agent Image Node Analyzer."
    fi

    if [ "$USE_PROMETHEUS" == true ]; then
      echo "    - Enable the Agent Prometheus collector."
    fi

    if [ "$USE_CLOUD" == true ]; then
      echo "    - Set up Instruqt tab with access to the Sysdig Dashboard."
      echo "    - Enable CloudVision."
    fi

    if [ "$USE_CLOUD_SCAN_ENGINE" == true ]; then
      echo "    - Deploys the Image Scanner for Cloud Registries."
    fi
    echo "  Follow the instructions below."
    echo
    echo "----------------------------------------------------------"
}

##
# Ask for Agent Key and deploy a Sysdig Agent.
##
function deploy_agent () {
    AGENT_DEPLOY_DATE=$(date -d '+2 hour' +"%F__%H_%M")
    echo ${AGENT_DEPLOY_DATE} > $WORK_DIR/agent_deploy_date
    
    echo "Configuring Sysdig Agent"
    echo -e "  Visit ${F_BOLD}${F_CYAN}$MONITOR_URL/#/settings/agentInstallation${F_CLEAR} to retrieve your Sysdig Agent Key."

    if [[ ${INSTRUQT_USER_ID} == "testuser-"* ]]; 
    then
        AGENT_ACCESS_KEY=$(echo -n ${TEST_AGENT_ACCESS_KEY} | base64 --decode)
    else
        read -p "  Insert your Sysdig Agent Key: " AGENT_ACCESS_KEY;
    fi

    echo -e "  The agent is being installed in the background.\n"
    ACCESSKEY=`echo ${AGENT_ACCESS_KEY} | tr -d '\r'`

    install_agent ${AGENT_DEPLOY_DATE} ${AGENT_ACCESS_KEY} ${AGENT_COLLECTOR}
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

    attempt=0
    MAX_ATTEMPTS=60 # 3 minutes
    CONNECTED_MSG="Sending scraper version"
    connected=false

    while [ "$connected" != true ] && [ $attempt -le $MAX_ATTEMPTS ]
    do
        sleep 3
        case "$INSTALL_WITH" in
            helm)
                kubectl logs -l app.kubernetes.io/instance=sysdig-agent -n sysdig-agent --tail=-1 2> /dev/null | grep -q "${CONNECTED_MSG}"
                ;;
            docker)
                docker logs sysdig-agent 2>&1 | grep -q "${CONNECTED_MSG}"
                ;;
            host)
                grep -q "${CONNECTED_MSG}" /opt/draios/logs/draios.log
                ;;
        esac

        if [ $? -eq 0 ]
        then
            connected=true
            break
        fi
        
        attempt=$(( $attempt + 1 ))
    done

    if [ "$connected" = true ]
    then
        case "$INSTALL_WITH" in
            helm)
                FOUND_COLLECTOR=`kubectl logs -l app.kubernetes.io/instance=sysdig-agent -n sysdig-agent --tail=-1 2> /dev/null | grep "collector:" | head -n1 | awk '{print $NF}'`
                ;;
            docker)
                FOUND_COLLECTOR=`docker logs sysdig-agent 2>&1 | grep "collector:" | head -n1 | awk '{print $NF}'`
                ;;
            host)
                FOUND_COLLECTOR=`grep "collector:" /opt/draios/logs/draios.log | head -n1 | awk '{print $NF}'`
                ;;
        esac

        if [ "${FOUND_COLLECTOR}" == "${AGENT_COLLECTOR}" ]
        then
            echo "  Sysdig Agent successfully installed."
            touch $WORK_DIR/user_data_AGENT_OK
        else
            echo "  FAIL"
            echo "  Agent connected to wrong region."
            echo "    Selected collector: ${AGENT_COLLECTOR}"
            echo "    Found collector: ${FOUND_COLLECTOR}"
            panic_msg
        fi
    else
        echo "  FAIL"
        echo "  Agent failed to connect to back-end. Check your Agent Key."
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
function track_has_cloud_account () {
    if [ ! -z "$INSTRUQT_AWS_ACCOUNTS" ]
    then
        CLOUD_PROVIDER=aws
        cloudvarname=INSTRUQT_AWS_ACCOUNT_${INSTRUQT_AWS_ACCOUNTS}_ACCOUNT_ID
        CLOUD_ACCOUNT_ID=${!cloudvarname}
    fi

    if [ ! -z "$INSTRUQT_GCP_PROJECTS" ]
    then
        CLOUD_PROVIDER=gcp
        cloudvarname=INSTRUQT_GCP_PROJECT_${INSTRUQT_GCP_PROJECTS}_PROJECT_ID
        CLOUD_ACCOUNT_ID=${!cloudvarname}

        # terraform config to use the service account with role.owner permissions.
        # the user account provided by instruqt do not have org-level permissions and these
        # are required for the sysdig-cloud GCP installer
        sakeyvarname=INSTRUQT_GCP_PROJECT_${INSTRUQT_GCP_PROJECTS}_SERVICE_ACCOUNT_KEY
        SA_KEY=${!sakeyvarname}
        echo $SA_KEY | base64 -d > creds.json # credentials for the Service Account
        export TF_VAR_project=$CLOUD_ACCOUNT_ID
        grep $CLOUD_ACCOUNT_ID /root/.bashrc || echo "export TF_VAR_project=\"$CLOUD_ACCOUNT_ID\"" >> /root/.bashrc

        # set the path for terraform to use the service account credentials
        export GOOGLE_CREDENTIALS=$(pwd)/creds.json
        echo "export GOOGLE_CREDENTIALS=$GOOGLE_CREDENTIALS" >> /root/.bashrc
    fi

    if [ ! -z "$INSTRUQT_AZURE_SUBSCRIPTIONS" ]
    then
        CLOUD_PROVIDER=azure
        cloudvarname=INSTRUQT_AZURE_SUBSCRIPTION_${INSTRUQT_AZURE_SUBSCRIPTIONS}_SUBSCRIPTION_ID
        CLOUD_ACCOUNT_ID=${!cloudvarname}
    fi

    if [ -z $CLOUD_PROVIDER ]
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
    CLOUD_CONNECTOR_DEPLOY_DATE=$(date -d '+2 hour' +"%F__%H_%M")
    CLOUD_CONNECTOR_DEPLOY_QUERY=$(date +"%FT%H:%M:%S") # get deployment date that match format and timezone of the date returned by sysdig API CloudProvidersLastSeen
    CLOUD_REGION=""
    echo ${CLOUD_CONNECTOR_DEPLOY_DATE} > $WORK_DIR/cloud_connector_deploy_date
    echo ${CLOUD_CONNECTOR_DEPLOY_QUERY} > $WORK_DIR/cloud_connector_deploy_query
    
    echo "Configuring Sysdig CloudVision for $CLOUD_PROVIDER"

    # we are defining here some values (region) but in future we might want the user to choose its region
    # right now there's not a reason to select one or another
    if [ $CLOUD_PROVIDER = "aws" ]
    then
        CLOUD_REGION="us-east-1"
    elif [ $CLOUD_PROVIDER = "gcp" ]
    then
        CLOUD_REGION="us-east1"
    elif [ $CLOUD_PROVIDER = "azure" ]
    then
        CLOUD_REGION="foo"
    fi

    echo -e "  CloudVision is being installed in the background.\n"

    source $TRACK_DIR/cloud/install_with_terraform.sh $CLOUD_PROVIDER $SYSDIG_SECURE_API_TOKEN $SECURE_URL $CLOUD_REGION $CLOUD_ACCOUNT_ID
}

##
# Test if the Cloud account is connected successfully.
##
function test_cloud_connector () {
    echo "    Testing if the cloud account is connected..."

    attempt=0
    MAX_ATTEMPTS=36 # 6 minutes
    connected=false

    while [ "$connected" != true ] && [ $attempt -le $MAX_ATTEMPTS ]
    do
        sleep 10
        
        # asks the sysdig secure API about cloud accounts (provider, account_id, date_last_seen)
        # ordered by date_last_seen (more recent first)
        # applies some filtering to use the output usable (date format, quotes, etc.)
        # and writes it to .cloudProvidersLastSeen
        curl -s --header "Content-Type: application/json"   \
        -H 'Authorization: Bearer '"${SYSDIG_SECURE_API_TOKEN}" \
        --request GET \
        https://secure.sysdig.com/api/cloud/v2/dataSources/accounts\?limit\=50\&offset\=0 \
        | jq -r '[.[] | {provider: .provider, id: .id, alias: .alias, lastSeen: .cloudConnectorLastSeenAt}] | sort_by(.lastSeen) | reverse | .[] | "\(.provider) \(.id) \(.alias) \(.lastSeen)"' \
        | cut -f1 -d"." \
        | awk ' { t = $1; $1 = $(NF); $(NF) = t; print; } ' \
        > .cloudProvidersLastSeen

        CLOUD_CONNECTOR_DEPLOY_QUERY_EPOCH=$(date --date "$CLOUD_CONNECTOR_DEPLOY_QUERY" +%s)

        while read line; do # reading each cloud provider connected to the sysdig account
            
            if [[ "${line}" =~ "${CLOUD_ACCOUNT_ID}" ]]
            then 
                # the account_id matches
                LAST_SEEN_DATE=$(echo "$line" | cut -d' ' -f1) # extract date
                [[ $LAST_SEEN_DATE == "null" ]] && LAST_SEEN_DATE_EPOCH=0 || LAST_SEEN_DATE_EPOCH=$(date --date "$LAST_SEEN_DATE" +%s)

                # is this account date_last_seen value greater than the deployment_date in this script?
                # ^ this means, we want the cloud account to be active now
                # Instruqt reuses the accounts, so we don't want a false positive for reusing an account
                if [[ "${LAST_SEEN_DATE_EPOCH}" > "${CLOUD_CONNECTOR_DEPLOY_QUERY_EPOCH}" ]]
                then
                    echo "    Found cloud account: $line"
                    connected=true
                    break
                fi
            fi
        done < .cloudProvidersLastSeen
        
        attempt=$(( $attempt + 1 ))
    done

    if [ "$connected" = true ]
    then
        echo "  Sysdig Vision successfully installed."
        touch $WORK_DIR/user_data_CLOUDVISION_OK
    else
        echo "  FAIL"
        echo "  Sysdig Vision installation went wrong. Use the provided channels to report this issue."
        panic_msg
    fi
}

##
# Delete files only needed while running the script.
##
function clean_setup () {

    if [ "$USE_AGENT" == true ]
    then
      if [ -f $WORK_DIR/user_data_AGENT_OK ]
      then
          rm $WORK_DIR/user_data_AGENT_OK
      else
          panic_msg
      fi
    fi

    if [ "$USE_MONITOR_API" == true ]
    then
      if [ -f $WORK_DIR/user_data_MONITOR_API_OK ]
      then
          rm $WORK_DIR/user_data_MONITOR_API_OK
      else
          panic_msg
      fi
    fi

    if [ "$USE_SECURE_API" == true ]
    then
      if [ -f $WORK_DIR/user_data_SECURE_API_OK ]
      then
          rm $WORK_DIR/user_data_SECURE_API_OK
      else
          panic_msg
      fi
    fi

    if [ -d $TRACK_DIR ]
    then
        # we used to remove these files, but they are useful for debugging.
        # Also, the terraform state file is good to keep it in case we need to destroy the assets
        # In most cases we don't care about this, as Instruqts manages the cleanup of the envs.
        mv $TRACK_DIR/ /tmp/
        test -f /root/creds.json && mv /root/creds.json /tmp/
        sed -i '/init.sh/d' /root/.profile  # removes the script from .profile so it is not executed in new challenges
        touch $WORK_DIR/user_data_OK # flag environment configured with user data
    else
        panic_msg
    fi
}

##
# Show help and script usage
##
function help () {
    echo
    echo "USAGE:"
    echo
    echo "  `basename $0` [OPTIONS...]"
    echo
    echo "Environment start up script. It can be used to:"
    echo "- deploy a Sysdig Agent "
    echo "- deploy Sysdig Secure for Cloud (AWS, GCP, Azure)"
    echo "- and/or set up some environment variables."
    echo ""
    echo "Review the options below to learn what's available."
    echo ""
    echo "WARNING: This script is meant to be used in training materials."
    echo "Do NOT use it in production."
    echo
    echo
    echo "OPTIONS:"
    echo
    echo "  -a, --agent                 Deploy a Sysdig Agent."
    echo "  -c, --cloud                 Set up environment for Sysdig Secure for Cloud."
    echo "  -h, --help                  Show this help."
    echo "  -m, --monitor               Set up environment for Monitor API usage."
    echo "  -n, --node-analyzer         Enable Node Analyzer. Use with -a/--agent."
    echo "  -N, --node-image-analyzer   Enable Image Node Analyzer. Use with -a/--agent."
    echo "  -p, --prometheus            Enable Prometheus. Use with -a/--agent."
    echo "  -s, --secure                Set up environment for Secure API usage."
    echo "  -r, --region                Set up environment with user's Sysdig Region for a track with a host."
    echo "  -q, --region-cloud          Set up environment with user's Sysdig Region for cloud track with a cloud account."
    echo "  -v, --vulnmanag             Enable Image Scanning with Sysdig Secure for Cloud. Use with -c/--cloud."
    echo
    echo
    echo "ENVIRONMENT VARIABLES:"
    echo
    echo "  INSTALL_WITH                Sets preferred installation method. Available"
    echo "                              options are 'helm', 'docker' and 'host'. If not"
    echo "                              set, it will default to what's available in your,"
    echo "                              checking first for 'helm', then 'docker', and"
    echo "                              finally 'host'."
    echo
    echo "  HELM_OPTS                   Additional options for Helm installation."
    echo
    echo "  DOCKER_OPTS                 Additional options for Docker installation."
    echo
    echo "  HOST_OPTS                   Additional options for Host installation."
    echo


}


##
# Check and consume script flags.
##
function check_flags () {
    while [ ! $# -eq 0 ]
    do
        case "$1" in
            --agent | -a)
                USE_AGENT=true
                USE_AGENT_REGION=true
                ;;
            --region | -r)
                USE_AGENT_REGION=true
                ;;
            --cloud | -c)
                USE_CLOUD=true
                USE_CLOUD_REGION=true
                USE_SECURE_API=true
                ;;
            --region-cloud | -q)
                USE_CLOUD_REGION=true
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
            --node-image-analyzer | -N)
                export USE_NODE_IMAGE_ANALYZER=true
                ;;
            --prometheus | -p)
                export USE_PROMETHEUS=true
                ;;
            --vulnmanag | -v)
                export USE_CLOUD_SCAN_ENGINE=true
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

    if (([ "$USE_NODE_ANALYZER" = true ] || [ "$USE_NODE_IMAGE_ANALYZER" = true ]) \
       ||  [ "$USE_PROMETHEUS" = true ]) && [ "$USE_AGENT" != true ]
    then
        echo "ERROR: Options only available with -a/--agent."
        exit 1
    fi
}

##
# Execute setup.
##
function setup () {
    mkdir -p $WORK_DIR/

    check_flags $@

    intro

    if [ "$USE_AGENT_REGION" = true ] || [ "$USE_CLOUD_REGION" = true ]
    then
        select_region
    fi

    if [ "$USE_MONITOR_API" = true ]
    then
        configure_API "MONITOR" ${MONITOR_URL} ${MONITOR_API_ENDPOINT}
    fi
    
    if [ "$USE_SECURE_API" = true ]
    then
        configure_API "SECURE" ${SECURE_URL} ${SECURE_API_ENDPOINT}
    fi

    if [ "$USE_AGENT" = true ]
    then
        deploy_agent
        test_agent
    fi

    if [ "$USE_CLOUD" = true ]
    then
        track_has_cloud_account
        deploy_cloud_connector
        test_cloud_connector
    fi
    
    clean_setup
}


################################    SCRIPT    #################################
setup $@
