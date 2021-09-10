#!/bin/bash

echo "Sysdig Agent install script for a k8s cluster using Helm"
echo ""
echo "Please enter your Access Key :"
read MY_AGENT_KEY
echo ""
echo "Select region to define collector address :"
PS3='Please select one of the options above: '
options=("US East" "US West" "EMEA" "Abort")
select opt in "${options[@]}"
do
    case $opt in
        "US East")
            MY_REGION_COLLECTOR=collector.sysdigcloud.com
            echo "Region $opt selected, collector set to collector.sysdigcloud.com"
            break
            ;;
        "US West")
            MY_REGION_COLLECTOR=ingest-us2.app.sysdig.com
            echo "Region $opt selected, collector set to https://ingest-us2.app.sysdig.com"
            break
            ;;
        "EMEA")
            MY_REGION_COLLECTOR=ingest-eu1.app.sysdig.com
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
    --set sysdig.accessKey=$MY_AGENT_KEY \
	--set sysdig.settings.collector=$MY_REGION_COLLECTOR \
    --set sysdig.settings.tags="cluster:training" \
    --set nodeAnalyzer.deploy=false \
    --set resources.requests.cpu=1 \
    --set resources.requests.memory=512Mi \
    --set resources.limits.cpu=2 \
    --set resources.limits.memory=2048Mi \
    -f values.yaml \
    sysdig/sysdig

exit 0