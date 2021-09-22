#!/bin/bash
# This script has some requirements that have to be meet before executing:
# execute Helm 3 and add sysdig repo
#       curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
#       helm version
#       helm repo add sysdig https://charts.sysdig.com
#
# TODO: include prompt to insert agent TAGS and educate on tagging every agent deployed

echo ""
echo "--------------------------------------------------------"
echo "Sysdig Agent install script for a k8s cluster using Helm"
echo "--------------------------------------------------------"

# define collector by default
COLLECTOR_ADDRESS=collector.sysdigcloud.com

# define access-key
echo ""
read -p "Please enter your Access Key: " ACCESSKEY

# define collector
echo ""
echo "Select region to define collector address :"
PS3='Please select one of the options above: '
options=("US East (default)" "US West" "EMEA" "Custom" "Abort")
select opt in "${options[@]}"
do
    case $opt in
        "US East (default)")
            #COLLECTOR_ADDRESS=collector.sysdigcloud.com
            echo "$opt selected, collector set to: ${COLLECTOR_ADDRESS}"
            break
            ;;
        "US West")
            COLLECTOR_ADDRESS=ingest-us2.app.sysdig.com
            echo "$opt selected, collector set to: ${COLLECTOR_ADDRESS}"
            break
            ;;
        "EMEA")
            COLLECTOR_ADDRESS=ingest-eu1.app.sysdig.com
            echo "$opt selected, collector set to: ${COLLECTOR_ADDRESS}"
            break
            ;;
        "Custom")
            read -p "Enter here your Sysdig Collector Address :" COLLECTOR_ADDRESS
            echo "$opt selected, collector set to: ${COLLECTOR_ADDRESS}"
            break
            ;;
        "Abort")
            exit 1
            ;;
        *) echo "Not an option: $REPLY. Select one of the following";;
    esac
done

# if [ ${#ACCESSKEY} -ge 10 ]; then read -p "Please enter your Access Key: " ACCESSKEY ; exit
# else echo "done"
# fi

# create sysdig-agent namespace
echo ""
echo "Creating namespace sysdig-agent"
kubectl create ns sysdig-agent

# deploy the agent using Helm 3
# note that node image analyzer has been disabled for this lab
echo ""
echo "Deploying with Helm"
helm install sysdig-agent \
    --namespace sysdig-agent \
    --set nodeImageAnalyzer.deploy=false \
    --set sysdig.accessKey=$ACCESSKEY \
    --set sysdig.settings.collector=$COLLECTOR_ADDRESS \
    --set sysdig.settings.tags="cluster:demoKNP" \
    --set nodeAnalyzer.deploy=false \
    --set resources.requests.cpu=1 \
    --set resources.requests.memory=512Mi \
    --set resources.limits.cpu=2 \
    --set resources.limits.memory=2048Mi \
    sysdig/sysdig

exit 0