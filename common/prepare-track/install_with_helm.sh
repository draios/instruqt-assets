#!/usr/bin/env bash
##
# Deploy a Sysdig Agent using Helm.
#
# Usage:
#   install_with_helm.sh $CLUSTER_NAME $ACCESS_KEY $HELM_REGION_ID $SECURE_API_TOKEN $COLLECTOR
#   (check ./init.sh to learn more about possible HELM_REGION_ID values )
#
##

OUTPUT=/opt/sysdig/helm_install.out
SOCKET_PATH=/var/run/containerd/containerd.sock
CLUSTER_NAME=$1
ACCESS_KEY=$2
HELM_REGION_ID=$3
SECURE_API_TOKEN=$4
COLLECTOR=$5
HELM_OPTS=""

# new hostnames, to avoid duplicated names as much as possible
function custom_hostnaming () {
    # Fetch current node names dynamically using kubectl
    current_hostnames=($(kubectl get nodes -o=jsonpath='{.items[*].metadata.name}'))
    # Array of new hostnames
    new_hostnames=()
    # Loop through each node
    for current_hostname in "${current_hostnames[@]}"; do
        # Generate a new hostname based on the current hostname and random string
        new_hostname="${current_hostname}_$(cat /opt/sysdig/random_string_OK)"
        new_hostname=$(echo "$new_hostname" | tr '_' '-')
        # Connect to each of the nodes to:
        #  - set new hostname in /etc/hostname
        #  - Add new entry to /etc/hosts with the new name
        if [[ $(hostname) != $current_hostname ]]; #it's a different host
        then
            ssh root@$current_hostname "hostnamectl set-hostname $new_hostname"
            ssh root@$current_hostname 'echo "127.0.0.1 '$new_hostname'" >> /etc/hosts'

        else # it's me
            hostnamectl set-hostname $new_hostname
            echo "127.0.0.1 $new_hostname" >> /etc/hosts
        fi

        # Rename the hostname in k8s
        kubectl annotate node "$current_hostname" "kubectl.kubernetes.io/hostname=$new_hostname"

    done
}

mkdir -p /var/run/containerd
ln -s /var/run/k3s/containerd/containerd.sock ${SOCKET_PATH}

helm repo add sysdig https://charts.sysdig.com >> ${OUTPUT} 2>&1
helm repo update >> ${OUTPUT} 2>&1

# ingest k8sAuditDetections via admission controller by default (with AC scanning disabled)
HELM_OPTS="--set admissionController.enabled=true \
	--set admissionController.verifySSL=false \
	--set admissionController.features.k8sAuditDetections=true \
	--set admissionController.scanner.enabled=false \
	--set admissionController.sysdig.secureAPIToken=${SECURE_API_TOKEN} ${HELM_OPTS}"

if [ "$USE_NODE_ANALYZER" = true ]
then
    HELM_OPTS="--set nodeAnalyzer.nodeAnalyzer.deploy=true \
    --set nodeAnalyzer.secure.vulnerabilityManagement.newEngineOnly=true \
    --set nodeAnalyzer.nodeAnalyzer.sslVerifyCertificate=false \
    --set nodeAnalyzer.nodeAnalyzer.runtimeScanner.deploy=true $HELM_OPTS"

    if [ "$USE_RUNTIME_VM" = true ]
    then
        HELM_OPTS="--set nodeAnalyzer.nodeAnalyzer.runtimeScanner.settings.eveEnabled=true \
	$HELM_OPTS"
    fi

    if [ "$USE_K8S" = false ]
    then
        HELM_OPTS="--set nodeAnalyzer.nodeAnalyzer.imageAnalyzer.containerdSocketPath="unix://${SOCKET_PATH}" \
	--set nodeAnalyzer.nodeAnalyzer.imageAnalyzer.extraVolumes.volumes[0].name=socketpath \
	--set nodeAnalyzer.nodeAnalyzer.imageAnalyzer.extraVolumes.volumes[0].hostPath.path=${SOCKET_PATH} \
        --set nodeAnalyzer.nodeAnalyzer.runtimeScanner.extraMounts[0].name=socketpath \
        --set nodeAnalyzer.nodeAnalyzer.runtimeScanner.extraMounts[0].mountPath=${SOCKET_PATH} $HELM_OPTS"
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
    HELM_OPTS="--set sysdig.settings.prometheus.enabled=true \
    -f $AGENT_CONF_DIR/prometheus.yaml $HELM_OPTS"
fi

if [ "$USE_RAPID_RESPONSE" = true ]100755 → 100644
    --set rapidResponse.rapidResponse.sslVerifyCertificate=false \
    --set rapidResponse.rapidResponse.passphrase=training_secret_passphrase $HELM_OPTS"
fi

# if [ "$USE_K8S" = false ]
# then
#     HELM_OPTS="--set agent.sysdig.settings.cri.socket_path=$SOCKET_PATH $HELM_OPTS"
# fi

# new hostnames, to avoid duplicated names as much as possible
custom_hostnaming

# echo "Deploying Sysdig Agent with Helm"
kubectl create ns sysdig-agent >> ${OUTPUT} 2>&1
helm upgrade --install sysdig-agent --namespace sysdig-agent \
    --set global.clusterConfig.name="${CLUSTER_NAME}" \
    --set global.sysdig.accessKey=${ACCESS_KEY} \
    --set global.sysdig.region=${HELM_REGION_ID} \
    --set agent.resourceProfile=custom \
    --set agent.resources.requests.cpu=1 \
    --set agent.resources.requests.memory=1024Mi \
    --set agent.resources.limits.cpu=2 \
    --set agent.resources.limits.memory=2048Mi \
    --set agent.sysdig.settings.drift_killer.enabled=true \
    --set agent.collectorSettings.sslVerifyCertificate=false \
    --set agent.collectorSettings.collectorHost=${COLLECTOR} \
    -f ${AGENT_CONF_DIR}/values.yaml \
    ${HELM_OPTS} \
sysdig/sysdig-deploy >> ${OUTPUT} 2>&1 &
