#!/bin/bash
#
# SYSDIG TRAINING
#
# Agent installer with docker
#


echo "Sysdig Agent install script using Docker"
echo 
read -p "Please enter your Sysdig Access Key:" ACCESSKEY
echo ""
echo ${ACCESSKEY} >> accesskey
sed -e "s/^M//" accesskey > newaccesskey
ACCESSKEY=`cat newaccesskey`
rm accesskey
rm newaccesskey
echo "Access key: " ${ACCESSKEY}
echo ""
echo "Select region to define collector address (number):"
PS3='Select region to define collector address (number): '
options=("US East (default)" "US West" "EMEA" "Other" "Abort")
select opt in "${options[@]}"
do
    case $opt in
        "US East (default)")
            echo "Region $opt selected, collector set to collector.sysdigcloud.com"
            COLLECTOR_ADDRESS=collector.sysdigcloud.com
            break
            ;;
        "US West")
            echo "Region $opt selected, collector set to ingest-us2.app.sysdig.com"
            COLLECTOR_ADDRESS=ingest-us2.app.sysdig.com
            break
            ;;
        "EMEA")
            echo "Region $opt selected, collector set to ingest-eu1.app.sysdig.com"
            COLLECTOR_ADDRESS=ingest-eu1.app.sysdig.com
            break
            ;;
        "Other")
            read -p "Enter collector address :" COLLECTOR_ADDRESS
            echo "Collector set to $COLLECTOR_ADDRESS"
            break
            ;;
        "Abort")
            echo "Installer aborted. Agent not installed."
            exit 1
            ;;
        *) echo "Not an option: $REPLY. Select region to define collector address (number):";;
    esac
done

docker run -d \
    --name sysdig-agent \
    --restart always \
    --privileged \
    --net host \
    --pid host \
    -e ACCESS_KEY=${ACCESSKEY} \
    -e COLLECTOR=${COLLECTOR_ADDRESS} \
    -e SECURE=true \
    -v /var/run/docker.sock:/host/var/run/docker.sock \
    -v /dev:/host/dev \
    -v /proc:/host/proc:ro \
    -v /boot:/host/boot:ro \
    -v /lib/modules:/host/lib/modules:ro \
    -v /usr:/host/usr:ro \
    -v /root/sysdig-agent/dragent.yaml:/opt/draios/etc/dragent.yaml:rw \
    -v /root/sysdig-agent/prometheus.yaml:/opt/draios/etc/prometheus.yaml:rw \
    --shm-size=512m \
sysdig/agent:10.5.0