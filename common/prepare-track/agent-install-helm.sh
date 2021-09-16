#!/bin/bash

#deploy agent, default to Helm for k3s env. Consider other alternatives later. Helm already installed
#curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash &> /dev/null
helm repo add sysdig https://charts.sysdig.com &> /dev/null
helm repo update &> /dev/null


# echo "Deploying Sysdig Agent with Helm"
kubectl create ns sysdig-agent &> /dev/null
helm install sysdig-agent \
    --set clusterName="instruqtk3s_${AGENT_DEPLOY_DATE}" \
    --set sysdig.settings.tags="instruqt:${AGENT_TR_ID}" \
    --namespace sysdig-agent \
    --set sysdig.accessKey=$AGENT_ACCESS_KEY \
    --set sysdig.settings.collector=$AGENT_COLLECTOR \
    --set nodeAnalyzer.deploy=false \
    --set nodeImageAnalyzer.deploy=false \
    --set resources.requests.cpu=0.5 \
    --set resources.requests.memory=512Mi \
    --set resources.limits.cpu=2 \
    --set resources.limits.memory=2048Mi \
    sysdig/sysdig &> /dev/null
# TODO: set version to match the available img.ver on our packer custom image