#!/bin/bash

#set -x

#trap '' 2 #signal capture quit with ctrlc

# define url and endpoints for the selected region.
# this is used to define the URL of the track-TABS, for API queries and define agent parameters
set_values () {
    if [[ ${REGION} == *"US West"* ]]
    then
        DOMAIN='us2.app.sysdig.com'
        MONITOR_URL='https://'$DOMAIN
        SECURE_URL=$MONITOR_URL'/secure/'
        AGENT_COLLECTOR='ingest-'$DOMAIN
        #endpoints
        MONITOR_API_ENDPOINT=$MONITOR_URL
        SECURE_API_ENDPOINT=$MONITOR_URL
        PROMETHEUS_ENDPOINT=$MONITOR_URL'/prometheus'
        NIA_ENDPOINT=$MONITOR_URL'/internal/scanning/scanning-analysis-collector'
    elif [[ ${REGION} == *"EMEA"* ]]
    then
        DOMAIN='eu1.app.sysdig.com'
        MONITOR_URL='https://'$DOMAIN
        SECURE_URL=$MONITOR_URL'/secure/'
        AGENT_COLLECTOR='ingest-'$DOMAIN
        #endpoints
        MONITOR_API_ENDPOINT=$MONITOR_URL
        SECURE_API_ENDPOINT=$MONITOR_URL
        PROMETHEUS_ENDPOINT=$MONITOR_URL'/prometheus'
        NIA_ENDPOINT=$MONITOR_URL'/internal/scanning/scanning-analysis-collector'
    else # default case, US East
        #DOMAIN=
        MONITOR_URL='https://app.sysdigcloud.com'
        SECURE_URL='https://secure.sysdig.com'
        AGENT_COLLECTOR='collector.sysdigcloud.com'
        #endpoints
        MONITOR_API_ENDPOINT=$MONITOR_URL
        SECURE_API_ENDPOINT=$MONITOR_URL
        PROMETHEUS_ENDPOINT=$MONITOR_URL'/prometheus'
        NIA_ENDPOINT='https://collector-static.sysdigcloud.com/internal/scanning/scanning-analysis-collector'
    fi

    #print selected data
    echo 
    echo "Region $REGION selected."
    echo "Use $MONITOR_URL & $SECURE_URL to access your Sysdig Monitor and Secure Dashboards"
    echo
    echo "Other parameters configured:"
    echo "  - Agent Collector=$AGENT_COLLECTOR" 
    echo "  - monitor_API_endpoind=$MONITOR_API_ENDPOINT"
    echo "  - secure_API_endpoind=$SECURE_API_ENDPOINT"
    echo "  - prometheus_endpoint=$PROMETHEUS_ENDPOINT" 
    echo "  - NIA_endpoint=$NIA_ENDPOINT" 

    # tabs url_redirect
    sed -i -e "s@_MONITOR_URL_@$MONITOR_URL@g" /etc/nginx/nginx.conf
    sed -i -e "s@_SECURE_URL_@$SECURE_URL@g" /etc/nginx/nginx.conf
    sudo systemctl restart nginx
}

select_region () {
    echo
    echo "Please select one of the existing SaaS Regions: "
    echo "   1) US East (default)"
    echo "   2) US West"
    echo "   3) EMEA"
    echo "   4) Abort install"
    read -p "   Select Region (type number): "  REGION_N; 
    
    if [[ ${REGION_N} == "1" ]]; then
        REGION="US East (default)"
        echo -n "${REGION} selected."
    elif [[ ${REGION_N} == "2" ]]; then
        REGION="US West"
        echo -n "${REGION} selected."
    elif [[ ${REGION_N} == "3" ]]; then
        REGION="EMEA"
        echo -n "${REGION} selected."
    elif [[ ${REGION_N} == "4" ]]; then
        echo -n "Abort init.sh. Region not defined, agent not installed. This track won't might not work properly."
        exit 0
    else 
        echo "${REGION_N} is not a valid an option."
        select_region
    fi

    #based on selected region, values are defined
    set_values $REGION
}

# invoque with:
# configure_API "MONITOR" ${MONITOR_URL} ${MONITOR_API_ENDPOINT}
# configure_API "PRODUCT" ${PRODUCT_URL} ${PRODUCT_API_ENDPOINT}
# example:
# configure_API "MONITOR" ${MONITOR_URL} ${MONITOR_API_ENDPOINT}
configure_API () {

    echo "Configuring Sysdig $1 API"
    echo -e "Visit \x1B[31m\e[1m$2/#/settings/user\e[0m to retrieve your Sysdig $1 API Token."
    declare ${1}_API_KEY=foo
    varname=${1}_API_KEY
    # echo ${varname}

    # PRODUCT=MONITOR
    # declare ${PRODUCT}_API_KEY=foofoo
    # varname=${PRODUCT}_API_KEY
    # eval echo -e "\$${varname}"

    x=0

    while [ ! -f /usr/local/bin/sysdig/user_data_${1}_API_OK ] && [ $x -le 7 ]; do

        x=$(( $x + 1 ))

        read -p "   Insert here your Sysdig $1 API Token: "  ${varname}; echo 
        #eval echo -e "esta es la clave: \$${varname}"

        # testing connection
        echo -n "Testing connection to API... "
        curl -s -H 'Authorization: Bearer '$(eval echo -e "\$${varname}") "$3"'/api/' | grep 'status":404' &> /dev/null

        if [ $? -eq 0 ]; then
            echo "OK"
            touch /usr/local/bin/sysdig/user_data_$1_API_OK
        else
            echo "FAIL"
            echo "Or the region selected (URL) is not your region or the key is wrong."

            #select_region #we can not just change the region, the agent is using the backend.
            #TODO: retry 3 times and if it still does not work, 
            # 1. remove sysdig-agent namespace
            # 2. define region again
            # 3. reinstall agent
            # 4. configure APIs again
        fi
    done
}


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
echo " Welcomed! This script installs your Sysdig Agent in a"
echo " k3s cluster with Helm, selects your Sysdig SaaS Region, "
echo " and configures your API tokens."
echo " Follow the instructions below."
echo
echo "----------------------------------------------------------"

#training agent unique identifier 
AGENT_TR_ID=$(xxd -l 3 -c 3 -p < /dev/random)
AGENT_DEPLOY_DATE=$(date +"%F_%H:%M")

mkdir -p /usr/local/bin/sysdig/
chmod +x /root/prepare-track/agent-install-helm.sh

# nginx is already installed by track-setup, we overwrite config
cp /root/prepare-track/nginx.default.conf /etc/nginx/nginx.conf

if [[ ${DEBUG_REGION} == "" ]]; then

    select_region

    echo 
    echo -e "Visit \x1B[31m\e[1m$MONITOR_URL/#/settings/agentInstallation\e[0m to retrieve your Sysdig Agent Key."
    read -p "   Insert your Sysdig Agent Key: " AGENT_ACCESS_KEY; echo 

    # this will install the agent while the user configure APIs, we save some time
    bash /root/prepare-track/agent-install-helm.sh &

    configure_API "MONITOR" ${MONITOR_URL} ${MONITOR_API_ENDPOINT}
    configure_API "SECURE" ${SECURE_URL} ${SECURE_API_ENDPOINT}

    # echo -e "Visit \x1B[31m\e[1m$SECURE_URL/#/settings/user\e[0m to retrieve your Sysdig Secure API Token."
    # read -p "   Insert your Sysdig Secure API Token: " SECURE_API_KEY; echo 

else
    REGION=$DEBUG_REGION
    AGENT_ACCESS_KEY=$DEBUG_AGENT_ACCESS_KEY
    MONITOR_API_KEY=$DEBUG_MONITOR_API_KEY
    SECURE_API_KEY=$DEBUG_SECURE_API_KEY
    set_values $REGION

    bash /root/prepare-track/agent-install-helm.sh &
fi

# test agent connection
echo -n "Testing Sysdig Agent running in your environment."
echo -n " It can take up to 2 minutes to connect with the backend..."

# sleep 120 &
# PID=$!
# i=1
# sp="/-\|"
# echo -n ' '
# while [ -d /proc/$PID ]
# do
#   printf "\b${sp:i++%${#sp}:1}"
#   sleep .1
# done

#define query
DATE=$(date +%s)
TIMETO=$(( $DATE ))
TIMETO=${TIMETO%?}
TIMETO+=0
TIMEFROM=$(( $TIMETO - 60 ))
TIMETO=$(( $TIMETO + 60 ))
#echo "DATE: " $DATE "TIMETO: " $TIMETO "TIMEFROM: " $TIMEFROM
TIMETO+=000000
TIMEFROM+=000000
cp /root/prepare-track/data.original.json /root/prepare-track/data.json
sed -i -e 's/"_TO"/'"$TIMETO"'/g' /root/prepare-track/data.json
sed -i -e 's/"_FROM"/'"$TIMEFROM"'/g' /root/prepare-track/data.json

#check if there's an agent running with same custom TAG
RESULT_AGENT=1
x=0

while [ RESULT_AGENT -ne 0 ] && [ $x -le 7 ]; do
    echo "|"
    sleep 5
    echo "|"
    sleep 5
    echo "|"
    sleep 5

    curl -s --header "Content-Type: application/json"   \
        -H 'Authorization: Bearer '"${MONITOR_API_KEY}" \
        --request POST \
        --data @/root/prepare-track/data.json \
        "${MONITOR_API_ENDPOINT}"/api/data/batch \
        | jq ".responses[].data[]" | grep -o "$AGENT_TR_ID"

    RESULT_AGENT=$?
    x=$(( $x + 1 ))
done

if [ RESULT_AGENT -eq 0 ]; then
	echo " OK"
    touch /usr/local/bin/sysdig/user_data_AGENT_OK
else
	echo "FAIL"
    echo "Or the region selected (URL) is not your region or the Agent Key is wrong."
fi

# Final Check and clean config files from environment in case of success
if  [ -f /usr/local/bin/sysdig/user_data_MONITOR_API_OK ] && \
    [ -f /usr/local/bin/sysdig/user_data_SECURE_API_OK ] && \
    [ -f /usr/local/bin/sysdig/user_data_AGENT_OK ]; then
        # the user configured all right, we can remove resources
        rm /usr/local/bin/data.json
        rm /usr/local/bin/data.json.original
        rm -rf /root/prepare-track/
        sed -i '/init.sh/d' /root/.profile  # removes the script from .profile so it is not executed in new challenges
        touch /usr/local/bin/sysdig/user_data_OK # flag environment configured with user data
else
        echo "Some errors were detected configuring this lab. Please, run again this script with:"
        echo "   source /root/prepare-track/init.sh"
        echo
        echo "You can ask for help using Intercom or get in touch with us in team-training@sysdig.com"
fi
