#!/usr/bin/env bash
##
# Deploy a Sysdig Agent using Helm.
#
# Usage:
#   install_with_helm.sh ${CLUSTER_NAME} ${ACCESS_KEY} ${COLLECTOR}
##

CLUSTER_NAME=$1
ACCESS_KEY=$2
COLLECTOR=$3

helm repo add sysdig https://charts.sysdig.com > /dev/null
helm repo update > /dev/null

if [ "$USE_NODE_ANALYZER" = true ]
then
    HELM_OPTS="--set nodeAnalyzer.deploy=true $HELM_OPTS"
else
    HELM_OPTS="--set nodeAnalyzer.deploy=false $HELM_OPTS"
fi

if [ "$USE_NODE_IMAGE_ANALYZER" = true ]
then
    HELM_OPTS="--set nodeImageAnalyzer.deploy=true $HELM_OPTS"
else
    HELM_OPTS="--set nodeImageAnalyzer.deploy=false $HELM_OPTS"
fi

if [ "$USE_PROMETHEUS" = true ]
then
    HELM_OPTS="--set prometheus.file=true $HELM_OPTS"
    HELM_OPTS="-f $AGENT_CONF_DIR/prometheus.yaml $HELM_OPTS"
fi

# echo "Deploying Sysdig Agent with Helm"
kubectl create ns sysdig-agent > /dev/null
helm install sysdig-agent \
    --set clusterName="insq_${CLUSTER_NAME}" \
    --namespace sysdig-agent \
    --set sysdig.accessKey=${ACCESS_KEY} \
    --set sysdig.settings.collector=${COLLECTOR} \
    --set resourceProfile=custom \
    --set resources.requests.cpu=1 \
    --set resources.requests.memory=1024Mi \
    --set resources.limits.cpu=2 \
    --set resources.limits.memory=2048Mi \
    -f $AGENT_CONF_DIR/values.yaml \
    ${HELM_OPTS} \
sysdig/sysdig > /dev/null
