#!/bin/bash

echo "Sysdig Agent install script for a k8s cluster using Helm"
echo ""
echo "Please enter your Access Key :"
read ACCESSKEY
echo ""
echo "Select region to define collector address :"
PS3='Please select one of the options above: '
options=("US East" "US West" "EMEA" "Abort")
select opt in "${options[@]}"
do
    case $opt in
        "US East")
            COLLECTOR_ADDRESS=collector.sysdigcloud.com
            echo "Region $opt selected, collector set to collector.sysdigcloud.com"
            break
            ;;
        "US West")
            COLLECTOR_ADDRESS=https://ingest-us2.app.sysdig.com
            echo "Region $opt selected, collector set to https://ingest-us2.app.sysdig.com"
            break
            ;;
        "EMEA")
            COLLECTOR_ADDRESS=https://ingest-eu1.app.sysdig.com
            echo "Region $opt selected, collector set to https://ingest-eu1.app.sysdig.com"
            break
            ;;
        "Abort")
            exit 1
            ;;
        *) echo "Not an option: $REPLY. Select one of the following";;
    esac
done

echo "Create namespace sysdig-agent"
kubectl create ns sysdig-agent

echo "Deploy with Helm"
helm install sysdig-agent \
    --namespace sysdig-agent \
    --set sysdig.accessKey=$ACCESSKEY \
	--set sysdig.settings.collector=$COLLECTOR_ADDRESS \
    --set sysdig.settings.tags="cluster:training" \
    --set nodeAnalyzer.deploy=false \
    sysdig/sysdig

exit 0
