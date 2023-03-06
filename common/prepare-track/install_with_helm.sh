#!/usr/bin/env bash
##
# Deploy a Sysdig Agent using Helm.
#
# Usage:
#   install_with_helm.sh ${CLUSTER_NAME} ${ACCESS_KEY} ${HELM_REGION_ID}
#   (check ./init.sh to learn more about possible HELM_REGION_ID values )
#
##

OUTPUT=/opt/sysdig/helm_install.out
SOCKET_PATH=/run/k3s/containerd/containerd.sock
CLUSTER_NAME=$1
ACCESS_KEY=$2
HELM_REGION_ID=$3

helm repo add sysdig https://charts.sysdig.com >> ${OUTPUT} 2>&1
helm repo update >> ${OUTPUT} 2>&1

if [ "$USE_NODE_ANALYZER" = true ]
then
    HELM_OPTS="--set nodeAnalyzer.nodeAnalyzer.deploy=true \
    --set nodeAnalyzer.secure.vulnerabilityManagement.newEngineOnly=true \
    --set nodeAnalyzer.imageAnalyzer.containerdSocketPath=$SOCKET_PATH $HELM_OPTS"
else
    HELM_OPTS="--set nodeAnalyzer.nodeAnalyzer.deploy=false $HELM_OPTS"
fi

if [ "$USE_KSPM" = true ]
then
    HELM_OPTS="--set global.kspm.deploy=true $HELM_OPTS"
else
    HELM_OPTS="--set global.kspm.deploy=false $HELM_OPTS"
fi

if [ "$USE_PROMETHEUS" = true ]
then
    HELM_OPTS="--set agent.prometheus.file=true $HELM_OPTS"
    HELM_OPTS="-f $AGENT_CONF_DIR/prometheus.yaml $HELM_OPTS"
fi

if [ "$USE_AUDIT_LOG" = true ]
then
    HELM_OPTS="--set agent.auditLog.enabled=true $HELM_OPTS"
    HELM_OPTS="--set agent.auditLog.auditServerUrl=0.0.0.0 $HELM_OPTS"
    HELM_OPTS="--set agent.auditLog.auditServerPort=7765 $HELM_OPTS"
fi

if [ "$USE_RAPID_RESPONSE" = true ]
then
    HELM_OPTS="--set rapidResponse.enabled=true \
    --set rapidResponse.rapidResponse.passphrase=training_secret_passphrase $HELM_OPTS"
fi

# echo "Deploying Sysdig Agent with Helm"
kubectl create ns sysdig-agent >> ${OUTPUT} 2>&1
helm install sysdig-agent --namespace sysdig-agent \
    --set global.clusterConfig.name="insq_${CLUSTER_NAME}" \
    --set global.sysdig.accessKey=${ACCESS_KEY} \
    --set global.sysdig.region=${HELM_REGION_ID} \
    --set agent.resourceProfile=custom \
    --set agent.resources.requests.cpu=1 \
    --set agent.resources.requests.memory=1024Mi \
    --set agent.resources.limits.cpu=2 \
    --set agent.resources.limits.memory=2048Mi \
    --set agent.sysdig.settings.cri.socket_path=$SOCKET_PATH \
    -f ${AGENT_CONF_DIR}/values.yaml \
    ${HELM_OPTS} \
sysdig/sysdig-deploy >> ${OUTPUT} 2>&1 &
