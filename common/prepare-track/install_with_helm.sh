#!/usr/bin/env bash
##
# Deploy a Sysdig Agent using Helm.
#
# Usage:
#   install_with_helm.sh ${CLUSTER_NAME} ${ACCESS_KEY} ${HELM_REGION_ID} ${SECURE_API_TOKEN}
#   (check ./init.sh to learn more about possible HELM_REGION_ID values )
#
##

OUTPUT=/opt/sysdig/helm_install.out
# SOCKET_PATH=/run/k3s/containerd/containerd.sock
CLUSTER_NAME=$1
ACCESS_KEY=$2
HELM_REGION_ID=$3
SECURE_API_TOKEN=$4
HELM_OPTS=""

mkdir -p /var/run/containerd
ln -s /var/run/k3s/containerd/containerd.sock /var/run/containerd/containerd.sock

helm repo add sysdig https://charts.sysdig.com >> ${OUTPUT} 2>&1
helm repo update >> ${OUTPUT} 2>&1

# ingest k8sAuditDetections via admission controller by default (with AC scanning disabled)
HELM_OPTS="--set admissionController.enabled=true \
	--set admissionController.features.k8sAuditDetections=true \
	--set admissionController.scanner.enabled=false \
	--set admissionController.sysdig.secureAPIToken=${SECURE_API_TOKEN} ${HELM_OPTS}"

if [ "$USE_NODE_ANALYZER" = true ]
then
    HELM_OPTS="--set nodeAnalyzer.nodeAnalyzer.deploy=true \
    --set nodeAnalyzer.secure.vulnerabilityManagement.newEngineOnly=true \
    --set nodeAnalyzer.nodeAnalyzer.runtimeScanner.deploy=true $HELM_OPTS"

    if [ "$USE_RUNTIME_VM" = true ]
    then
        HELM_OPTS="--set nodeAnalyzer.nodeAnalyzer.runtimeScanner.settings.eveEnabled=true $HELM_OPTS"
    fi

    if [ "$USE_K8S" = false ]
    then
        HELM_OPTS="--set nodeAnalyzer.nodeAnalyzer.imageAnalyzer.containerdSocketPath="unix:///var/run/containerd/containerd.sock" \
        --set nodeAnalyzer.nodeAnalyzer.imageAnalyzer.extraVolumes.volumes[0].name=socketpath \
        --set nodeAnalyzer.nodeAnalyzer.imageAnalyzer.extraVolumes.volumes[0].hostPath.path=/var/run/containerd/containerd.sock \
        --set nodeAnalyzer.nodeAnalyzer.runtimeScanner.extraMounts[0].name=socketpath \
        --set nodeAnalyzer.nodeAnalyzer.runtimeScanner.extraMounts[0].mountPath=/var/run/containerd/containerd.sock $HELM_OPTS"
    fi
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

if [ "$USE_RAPID_RESPONSE" = true ]
then
    HELM_OPTS="--set rapidResponse.enabled=true \
    --set rapidResponse.rapidResponse.passphrase=training_secret_passphrase $HELM_OPTS"
fi

# if [ "$USE_K8S" = false ]
# then
#     HELM_OPTS="--set agent.sysdig.settings.cri.socket_path=$SOCKET_PATH $HELM_OPTS"
# fi

# echo "Deploying Sysdig Agent with Helm"
kubectl create ns sysdig-agent >> ${OUTPUT} 2>&1
helm upgrade --install sysdig-agent --namespace sysdig-agent \
    --set global.clusterConfig.name="insq_${CLUSTER_NAME}" \
    --set global.sysdig.accessKey=${ACCESS_KEY} \
    --set global.sysdig.region=${HELM_REGION_ID} \
    --set agent.resourceProfile=custom \
    --set agent.resources.requests.cpu=1 \
    --set agent.resources.requests.memory=1024Mi \
    --set agent.resources.limits.cpu=2 \
    --set agent.resources.limits.memory=2048Mi \
    --set agent.sysdig.settings.drift_killer.enabled=true \
    ${HELM_OPTS} \
sysdig/sysdig-deploy >> ${OUTPUT} 2>&1 &