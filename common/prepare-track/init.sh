#!/usr/bin/env bash
###
# Sysdig Agent deploy helper for Sysdig Training tracks.
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
USE_AUDIT_LOG=false

##############################    GLOBAL VARS    ##############################
TEST_AGENT_ACCESS_KEY=ZTRlNDFiMGUtYTg5Yi00YWU4LWJlZjYtMzA4Y2FmZDIwMjAx
TEST_MONITOR_API=MzI1NGFhODktYTcyZi00ZDlkLWJkMWEtMGYzZjQyZjc2ZTgw
TEST_SECURE_API=ZDg2NGY1YmUtNThiNi00OTUyLWI0ODItY2I1OWJkMTMzZjZj
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
# Define URL and endpoints for the selected region.
#
# This is used to define the URL of the track-TABS, for API queries and define
# agent parameters.
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

    # Tabs url_redirect
    sed -i -e "s@_MONITOR_URL_@$MONITOR_URL@g" /etc/nginx/nginx.conf
    sed -i -e "s@_SECURE_URL_@$SECURE_URL@g" /etc/nginx/nginx.conf
    systemctl restart nginx
}

##
# Prompt user to select agent collector (region).
##
function select_region () {
    echo
    echo "Please select one of the existing SaaS Regions: "
    echo "   1) GCP US West (default)"
    echo "   2) AWS US East"
    echo "   3) AWS US West"
    echo "   4) EMEA"
    echo "   5) Pacific"
    echo "   6) Abort install"

    if [[ ${INSTRUQT_USER_ID} == "testuser-"* ]]; 
    then
        REGION_N=${TEST_REGION}
    else
        read -p "   Select Region (type number): "  REGION_N; 
    fi

    case $REGION_N in
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
        6)
            echo "   Abort init.sh. Region not defined, agent not installed. This track will not work properly."
            exit 0
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
# Configure Sysdig API access.
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
# Selects the installation method depending on the environment.
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

    if [ "$USE_MONITOR_API" == true ]; then
      echo "    - Set up the environment for Monitor API usage."
    fi

    if [ "$USE_SECURE_API" == true ]; then
      echo "    - Set up the environment for Secure API usage."
    fi

    if [ "$USE_AGENT" == true ]; then
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

    if [ "$USE_AUDIT_LOG" == true ]; then
      echo "    - Enable K8s audit log support for Sysdig Secure."
    fi

    echo "  Follow the instructions below."
    echo
    echo "----------------------------------------------------------"
}

##
# Ask for region, Agent Key and accordingly deploy a Sysdig Agent.
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
        rm -rf $TRACK_DIR/
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
    echo "Environment start up script. It can be used to deploy a Sysdig Agent and/or set"
    echo "up some environment variables. When called with NO OPTIONS, it will deploy an"
    echo "Agent and will ask for Monitor and Secure API keys; same as calling with"
    echo "'-a/--agent -m/--monitor -s/--secure'. When using the product options"
    echo "('-m/--monitor' and/or '-s/--secure'), API keys will be stored in file"
    echo "$WORK_DIR/user_data_\${PRODUCT}_API_OK, and exported to envvar"
    echo "\$SYSDIG_\${PRODUCT}_API_TOKEN (where \${PRODUCT} is MONITOR or SECURE)."
    echo
    echo "WARNING: This script is meant to be used in training materials. Do NOT use it in"
    echo "production."
    echo
    echo
    echo "OPTIONS:"
    echo
    echo "  -a, --agent                 Deploy a Sysdig Agent."
    echo "  -h, --help                  Show this help."
    echo "  -m, --monitor               Set up environment for Monitor API usage."
    echo "  -n, --node-analyzer         Enable Node Analyzer. Use with -a/--agent."
    echo "  -N, --node-image-analyzer   Enable Image Node Analyzer. Use with -a/--agent."
    echo "  -p, --prometheus            Enable Prometheus. Use with -a/--agent."
    echo "  -s, --secure                Set up environment for Secure API usage."
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
}


##
# Check and consume script flags.
##
function check_flags () {
    if [ $# -eq 0 ]
    then
        USE_AGENT=true
        USE_MONITOR_API=true
        USE_SECURE_API=true
    else
        while [ ! $# -eq 0 ]
        do
            case "$1" in
                --agent | -a)
                    USE_AGENT=true
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
                --log | -l)
                    export USE_AUDIT_LOG=true
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
    fi

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

    cp $TRACK_DIR/nginx.default.conf /etc/nginx/nginx.conf

    check_flags $@

    intro

    select_region

    if [ "$USE_AGENT" = true ]
    then
        deploy_agent
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
        test_agent
    fi

    clean_setup
}


################################    SCRIPT    #################################
setup $@
