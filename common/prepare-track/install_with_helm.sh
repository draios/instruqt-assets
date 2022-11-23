#!/usr/bin/env bash
##
# Deploy a Sysdig Agent using Helm.
#
# Usage:
#   install_with_helm.sh ${CLUSTER_NAME} ${ACCESS_KEY} ${COLLECTOR}
##

OUTPUT=/opt/sysdig/helm_install.out
SOCKET_PATH=/run/k3s/containerd/containerd.sock
CLUSTER_NAME=$1
ACCESS_KEY=$2
COLLECTOR=$3

helm repo add sysdig https://charts.sysdig.com >> ${OUTPUT} 2>&1
helm repo update >> ${OUTPUT} 2>&1

if [ "$USE_NODE_ANALYZER" = true ]
then
    HELM_OPTS="--set nodeAnalyzer.deploy=true $HELM_OPTS"
else
    HELM_OPTS="--set nodeAnalyzer.deploy=false $HELM_OPTS"
fi

if [ "$USE_NODE_IMAGE_ANALYZER" = true ]
then
    HELM_OPTS="--set nodeImageAnalyzer.deploy=true \
               --set nodeImageAnalyzer.settings.containerdSocketPath=unix://$SOCKET_PATH \
               $HELM_OPTS"
else
    HELM_OPTS="--set nodeImageAnalyzer.deploy=false $HELM_OPTS"
fi

if [ "$USE_PROMETHEUS" = true ]
then
    HELM_OPTS="--set prometheus.file=true $HELM_OPTS"
    HELM_OPTS="-f $AGENT_CONF_DIR/prometheus.yaml $HELM_OPTS"
fi

if [ "$USE_AUDIT_LOG" = true ]
then
    HELM_OPTS="--set auditLog.enabled=true $HELM_OPTS"
fi

# echo "Deploying Sysdig Agent with Helm"
kubectl create ns sysdig-agent >> ${OUTPUT} 2>&1
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
    --set sysdig.settings.cri.socket_path=$SOCKET_PATH \
    -f ${AGENT_CONF_DIR}/values.yaml \
    ${HELM_OPTS} \
sysdig/sysdig >> ${OUTPUT} 2>&1 &
