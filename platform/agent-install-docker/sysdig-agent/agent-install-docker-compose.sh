#!/bin/bash
#
# SYSDIG TRAINING
#
# this is an example of how your command should look like (after indenting it)
#
# if you are using this file, remember to:
# 		- UPDATE your ACCESS_KEY
# 		- include TAGS
#

echo "Sysdig Agent install script using Docker"
echo 
read -p "Please enter your Sysdig Key :" ACCESSKEY
echo 
echo "Select region to define collector address :"
PS3='Please select one of the options above (type name or number): '
options=("US East (default)" "US West" "EMEA" "Abort install")
select opt in "${options[@]}"
do
    case $opt in
        "US East (default)")
            COLLECTOR_ADDRESS='collector.sysdigcloud.com'
            echo "Region $opt selected, collector set to collector.sysdigcloud.com"
            break
            ;;
        "US West")
            COLLECTOR_ADDRESS='ingest-us2.app.sysdig.com'
            echo "Region $opt selected, collector set to https://ingest-us2.app.sysdig.com"
            break
            ;;
        "EMEA")
            COLLECTOR_ADDRESS='ingest-eu1.app.sysdig.com'
            echo "Region $opt selected, collector set to https://ingest-eu1.app.sysdig.com"
            break
            ;;
        "Abort")
            exit 1
            ;;
        *) echo "Not an option: $REPLY. Select one of the following";;
    esac
done

export AGENT_KEY=${ACCESSKEY}
export AGENT_COLLECTOR=${COLLECTOR_ADDRESS}

docker-compose up -d

# AGAIN: node image analizer, should we include it here too?
