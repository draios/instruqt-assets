#!/usr/bin/env bash
###
# Sysdig Agent deploy helper for Sysdig Training tracks.
#
# AUTHORS:
#   Pablo J. López Zaldívar <pablo.lopezzaldivar@sysdig.com>
#   Paul Hodgetts <paul.hodgetts@sysdig.com>
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


###############################    FUNCTIONS    ###############################
##
# Message to display when ran into an issue
##
function panic_msg () {
    echo
    echo "Some errors were detected configuring this lab. Please, run again this script with:"
    echo "   source $TRACK_DIR/init.sh"
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
        *"US West"*)
            DOMAIN='us2.app.sysdig.com'
            MONITOR_URL='https://'$DOMAIN
            SECURE_URL=$MONITOR_URL'/secure/'
            AGENT_COLLECTOR='ingest-'$DOMAIN
            NIA_ENDPOINT=$MONITOR_URL'/internal/scanning/scanning-analysis-collector'
            ;;
        
        *"EMEA"*)
            DOMAIN='eu1.app.sysdig.com'
            MONITOR_URL='https://'$DOMAIN
            SECURE_URL=$MONITOR_URL'/secure/'
            AGENT_COLLECTOR='ingest-'$DOMAIN
            NIA_ENDPOINT=$MONITOR_URL'/internal/scanning/scanning-analysis-collector'
            ;;

        *"Pacific"*)
            DOMAIN='app.au1.sysdig.com'
            MONITOR_URL='https://'$DOMAIN
            SECURE_URL=$MONITOR_URL'/secure/'
            AGENT_COLLECTOR='ingest.au1.sysdig.com'
            NIA_ENDPOINT=$MONITOR_URL'/internal/scanning/scanning-analysis-collector'
            ;;
        
        *) # Default to US East
            MONITOR_URL='https://app.sysdigcloud.com'
            SECURE_URL='https://secure.sysdig.com'
            AGENT_COLLECTOR='collector.sysdigcloud.com'        
            NIA_ENDPOINT='https://collector-static.sysdigcloud.com/internal/scanning/scanning-analysis-collector'
            ;;
    esac

    MONITOR_API_ENDPOINT=$MONITOR_URL
    SECURE_API_ENDPOINT=$MONITOR_URL
    PROMETHEUS_ENDPOINT=$MONITOR_URL'/prometheus'

    # Print selected data
    echo 
    echo -e "   Use ${F_BOLD}${F_CYAN}$MONITOR_URL${F_CLEAR} & ${F_BOLD}${F_CYAN}$SECURE_URL${F_CLEAR} to access your Sysdig Monitor and Secure Dashboards"
    echo
    echo "Other parameters configured:"
    echo "  - Agent Collector=$AGENT_COLLECTOR" 
    echo "  - monitor_API_endpoind=$MONITOR_API_ENDPOINT"
    echo "  - secure_API_endpoind=$SECURE_API_ENDPOINT"
    echo "  - prometheus_endpoint=$PROMETHEUS_ENDPOINT" 
    echo "  - NIA_endpoint=$NIA_ENDPOINT" 

    # Tabs url_redirect
    sed -i -e "s@_MONITOR_URL_@$MONITOR_URL@g" /etc/nginx/nginx.conf
    sed -i -e "s@_SECURE_URL_@$SECURE_URL@g" /etc/nginx/nginx.conf
    sudo systemctl restart nginx
}

##
# Prompt user to select agent collector (region).
##
function select_region () {
    echo
    echo "Please select one of the existing SaaS Regions: "
    echo "   1) US East (default)"
    echo "   2) US West"
    echo "   3) EMEA"
    echo "   4) Pacific"
    echo "   5) Abort install"
    read -p "   Select Region (type number): "  REGION_N; 
    
    case $REGION_N in
        1)
            REGION="US East (default)"
            ;;
        2)
            REGION="US West"
            ;;
        3)
            REGION="EMEA"
            ;;
        4)
            REGION="Pacific"
            ;;
        5)
            echo "   Abort init.sh. Region not defined, agent not installed. This track won't might not work properly."
            exit 0
            ;;
        *)
            echo "${REGION_N} is not a valid an option."
            select_region
            ;;
    esac

    #based on selected region, values are defined
    echo -n "   ${REGION} selected."
    set_values $REGION
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
    echo -e "Visit ${F_BOLD}${F_CYAN}${PRODUCT_URL}/#/settings/user${F_CLEAR} to retrieve your Sysdig ${PRODUCT} API Token."
    varname=${PRODUCT}_API_KEY

    attempt=0
    MAX_ATTEMPTS=7

    while [ ! -f $WORK_DIR/user_data_${PRODUCT}_API_OK ] && [ $attempt -le $MAX_ATTEMPTS ]
    do
        attempt=$(( $attempt + 1 ))

        read -p "   Insert here your Sysdig $PRODUCT API Token: "  API_TOKEN; 

        # Test connection
        echo -n "   Testing connection to API... "
        curl -sD - -o /dev/null -H "Authorization: Bearer ${API_TOKEN}" "${PRODUCT_API_ENDPOINT}"'/api/alerts' | grep 'HTTP/2 200'
        
        if [ $? -eq 0 ]
        then
            echo "OK"         
            echo "${API_TOKEN}" > $WORK_DIR/user_data_${PRODUCT}_API_OK
            export SYSDIG_${PRODUCT}_API_TOKEN="${API_TOKEN}"
        else
            echo "FAIL. Either the slected region (URL) is not your region or the key is wrong."
            panic_msg
        fi
        echo
    done
}

##
# Selects the installation method depending on the environment.
##
function installation_method () {
    if [[ -z "$INSTALL_WITH"]]
    then
        if [ `which helm` ]
        then
            INSTALL_WITH="helm"
        elif [ `which docker` ]
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

    bash install_with_${INSTALL_WITH}.sh $CLUSTER_NAME $ACCESS_KEY $COLLECTOR
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
    echo " Welcome! This script installs your Sysdig Agent in a"
    echo " k3s cluster with Helm, selects your Sysdig SaaS Region, "
    echo " and configures your API tokens."
    echo " Follow the instructions below."
    echo
    echo "----------------------------------------------------------"
}

##
# Ask for region, Agent Key and accordingly deploy a Sysdig Agent.
##
function deploy_agent () {
    AGENT_DEPLOY_DATE=$(date -d '+2 hour' +"%F__%H_%M")

    echo 
    echo -e "Visit ${F_BOLD}${F_CYAN}$MONITOR_URL/#/settings/agentInstallation${F_CLEAR} to retrieve your Sysdig Agent Key."
    read -p "   Insert your Sysdig Agent Key: " AGENT_ACCESS_KEY; 
    echo 
    ACCESSKEY=`echo ${AGENT_ACCESS_KEY} | tr -d '\r'`

    install_agent ${AGENT_DEPLOY_DATE} ${AGENT_ACCESS_KEY} ${AGENT_COLLECTOR}
}

##
# Test if the Agent connected successfully to the collector endpoint.
##
function test_agent () {
    # test agent connection
    echo -n "Testing Sysdig Agent running in your environment."

    attempt=0
    MAX_ATTEMPTS=7
    connected=false

    while [ "$connected" != true ] && [ $attempt -le $MAX_ATTEMPTS ]
    do
        sleep 3
        kubectl logs -l app.kubernetes.io/instance=sysdig-agent -n sysdig-agent --tail=10000 | grep "Connected to collector" &> /dev/null

        if [ $? -eq 0 ]
        then
            connected=true
        fi
        
        attempt=$(( $attempt + 1 ))
    done

    kubectl logs -l app.kubernetes.io/instance=sysdig-agent -n sysdig-agent --tail=10000 | grep $AGENT_COLLECTOR &> /dev/null
    if [ $? -ne 0 ]
    then
        echo " FAIL"
        echo
        echo "  Either the slected region (URL) is not your region."
        panic_msg
    fi

    if [ "$connected" = true ]
    then
        echo " OK"
        touch $WORK_DIR/user_data_AGENT_OK
    else
        echo " FAIL"
        echo
        echo "  Either the selected region (URL) is not your region or the Agent Key is wrong."
        panic_msg
    fi
}

##
# Delete files only needed while running the script.
##
function clean_setup () {

    if [ -f $WORK_DIR/user_data_AGENT_OK ]
    then
        rm $WORK_DIR/user_data_AGENT_OK
    else
        panic_msg
    fi

    if [ -f $WORK_DIR/user_data_MONITOR_API_OK ]
    then
        rm $WORK_DIR/user_data_MONITOR_API_OK
    else
        panic_msg
    fi

    if [ -f $WORK_DIR/user_data_SECURE_API_OK ]
    then
        rm $WORK_DIR/user_data_SECURE_API_OK
    else
        panic_msg
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

    if [[ [[ [[ "$USE_NODE_ANALYZER" = true  \
             || "$USE_NODE_IMAGE_ANALYZER" = true ]] \
          ||  "$USE_PROMETHEUS" = true ]] \
       && "$USE_AGENT" != true ]]
    then
        echo "ERROR: Options only available with -a/--agent."
        exit 1
    fi
}

##
# Execute setup.
##
function setup () {
    check_flags $@
    select_region

    if [ "$USE_MONITOR_API" = true ]
    then
        configure_API "MONITOR" ${MONITOR_URL} ${MONITOR_URL}
    fi
    
    if [ "$USE_SECURE_API" = true ]
    then
        configure_API "SECURE" ${SECURE_URL} ${SECURE_URL}
    fi

    mkdir -p $WORK_DIR/
    # chmod +x $TRACK_DIR/agent-install-helm.sh

    # nginx is already installed by track-setup, we overwrite config
    cp $TRACK_DIR/nginx.default.conf /etc/nginx/nginx.conf

    if [ "$USE_AGENT" = true ]
    then
        deploy_agent
        test_agent
    fi
}


################################    SCRIPT    #################################
setup $@