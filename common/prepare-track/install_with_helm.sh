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
SSH_OPTS="-o StrictHostKeyChecking=no"
SECURE_API_ENDPOINT=$(echo "$6" | sed 's|https://||')
HELM_OPTS="${HELM_OPTS:-}"

HELM_OPTS="--set host.additional_settings.falcobaseline.report_interval=150000000000 \
--set host.additional_settings.falcobaseline.max_drops_buffer_rate_percentage=0.99 \
--set host.additional_settings.falcobaseline.max_sampling_ratio=128 \
--set host.additional_settings.falcobaseline.debug_metadata=true \
--set host.additional_settings.falcobaseline.debug=true \
--set host.additional_settings.falcobaseline.randomize_start=false \
--version=1.11.0 \
$HELM_OPTS"

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
            ssh $SSH_OPTS root@$current_hostname "hostnamectl set-hostname $new_hostname"
            ssh $SSH_OPTS root@$current_hostname "echo '127.0.0.1 $new_hostname' >> /etc/hosts"

        else # it's me
            hostnamectl set-hostname $new_hostname
            echo "127.0.0.1 $new_hostname" >> /etc/hosts
        fi

        # Rename the hostname in k8s
        kubectl annotate node "$current_hostname" "kubectl.kubernetes.io/hostname=$new_hostname"

    done
}

mkdir -p /var/run/containerd
if [ -e ${SOCKET_PATH} ]; then
  echo "File ${SOCKET_PATH} already exists."
else
  echo "File does not exist. Creating symlink."
  ln -s /var/run/k3s/containerd/containerd.sock ${SOCKET_PATH}
fi

helm repo add sysdig https://charts.sysdig.com >> ${OUTPUT} 2>&1
helm repo update >> ${OUTPUT} 2>&1

# ingest k8sAuditDetections via admission controller by default (with AC scanning disabled)
HELM_OPTS="--set features.detections.kubernetes_audit.enabled=true \
	--set features.investigations.activity_audit.enabled=true  ${HELM_OPTS}"

if [ "$USE_NODE_ANALYZER" = true ]
then
    HELM_OPTS="\
    --set features.vulnerability_management.host_vulnerability_management.enabled=true \
    --set features.vulnerability_management.container_vulnerability_management.enabled=true \
    --set features.vulnerability_management.container_vulnerability_management.registry_ssl.verify=false \
    --set features.vulnerability_management.in_use.enabled=true \
    --set features.vulnerability_management.in_use.integration_enabled=false $HELM_OPTS"
fi

if [ "$USE_KSPM" = true ]
then
    HELM_OPTS="--set features.posture.host_posture.enabled=true \
    --set features.kubernetes_metadata.enabled=true \
    --set features.posture.cluster_posture.enabled=true $HELM_OPTS"
fi

if [ "$USE_PROMETHEUS" = true ]
then
    HELM_OPTS="--set features.monitor.prometheus.enabled=true $HELM_OPTS"
fi

if [ "$USE_RAPID_RESPONSE" = true ]
then
    HELM_OPTS="--set features.respond.rapid_response.enabled=true $HELM_OPTS"
fi

if [ "$USE_ADMISSION_CONTROL" = true ]
then
    HELM_OPTS="--set features.admission_control.enabled=true \
    --set features.admission_control.container_vulnerability_management.enabled=true \
    --set features.admission_control.posture.enabled=true $HELM_OPTS"
fi

if [ "$USE_RESPONSE_ACTIONS" = true ]
then
    HELM_OPTS="--set features.respond.response_actions.enabled=true $HELM_OPTS"
fi

if [ "$WAIT_ENABLED" = true ]
then
    HELM_OPTS="--wait --timeout 15m $HELM_OPTS"
fi

# new hostnames, to avoid duplicated names as much as possible
custom_hostnaming

# echo "Deploying Sysdig Agent with Helm"
kubectl create ns sysdig-agent >> ${OUTPUT} 2>&1
(set -x; helm upgrade --install sysdig-agent --namespace sysdig-agent --create-namespace \
    --set cluster_config.name="${CLUSTER_NAME}" \
    --set sysdig_endpoint.access_key="${ACCESS_KEY}" \
    --set sysdig_endpoint.region="${HELM_REGION_ID}" \
    --set features.detections.kubernetes_audit.enabled=true \
    --set features.detections.drift_control.enabled=true \
    --set features.detections.malware_control.enabled=true \
    --set features.detections.ml_policies.enabled=true \
    --set features.investigations.network_security.enabled=true \
    --set features.investigations.captures.enabled=true \
    --set ssl.verify=false \
    --set sysdig_endpoint.collector.host="${COLLECTOR}" ${HELM_OPTS} \
sysdig/shield >> ${OUTPUT} 2>&1)

# kubectl wait --for=condition=Ready daemonset/sysdig-agent -n sysdig-agent --timeout=300s
