#!/bin/bash
#
# SYSDIG TRAINING
# Sysdig Agent docker installer with Access Key and Region Prompts
#

echo "Sysdig Agent install script using Docker"
echo 
read -p "Please enter your Sysdig Key (Settings > Agent Installation > Access Key): " ACCESSKEY
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

# install
docker run -d \
	--name sysdig-agent \
	--restart always \
	--privileged \
	--net host \
	--pid host \
	-e ACCESS_KEY=${ACCESSKEY} \
	-e COLLECTOR=${COLLECTOR_ADDRESS} \
	-e SECURE=true \
	-e TAGS=mode:training \
	-v /var/run/docker.sock:/host/var/run/docker.sock \
	-v /dev:/host/dev \
	-v /proc:/host/proc:ro \
	-v /boot:/host/boot:ro \
	-v /lib/modules:/host/lib/modules:ro \
	-v /usr:/host/usr:ro \


	--shm-size=512m \
sysdig/agent

# PABLO & JOHN REVIEW:
# node image analizer, should we include it here too?
# not sure if with docker is the best use case for this tool
