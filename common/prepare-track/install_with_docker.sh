#!/usr/bin/env bash
##
# Deploy a Sysdig Agent using Docker.
#
# Usage:
#   install_with_docker.sh ${CLUSTER_NAME} ${ACCESS_KEY} ${COLLECTOR}
##

OUTPUT=/opt/sysdig/docker_install.out
CLUSTER_NAME=$1
ACCESS_KEY=$2
COLLECTOR=$3

if [ "$USE_NODE_ANALYZER" = true ]
then
    if [ -n "$NIA_ENDPOINT" ]
    then
        docker run -d --name sysdig-node-image-analyzer \
            --privileged \
            --network host \
            -e AM_COLLECTOR_ENDPOINT=${NIA_ENDPOINT} \
            -e ACCESS_KEY=${ACCESS_KEY} \
            -e SCHEDULE=@dailydefault \
            -v /:/host:ro  \
            quay.io/sysdig/host-analyzer:latest >> ${OUTPUT} 2>&1 &
    else
        echo "ERROR: Cannot deploy Node Analyzer. No valid endpoint."
    fi
fi

if [ -n "$NIA_ENDPOINT" ]
then

    docker run --detach --name sysdig-host-scanner \
         -e HOST_FS_MOUNT_PATH=/host \
         -e SYSDIG_ACCESS_KEY=${ACCESS_KEY} \
         -e SYSDIG_API_URL=${NIA_ENDPOINT} \
         -e SCAN_ON_START=true \
         -e DOCKER_SOCKET_PATHS=unix:///host/var/run/docker.sock \
         -v /:/host:ro \
         -v /var/run:/host/var/run:ro \
         --uts=host \
         --net=host \
         quay.io/sysdig/vuln-host-scanner:$(curl -L -s https://download.sysdig.com/scanning/sysdig-host-scanner/latest_version.txt) >> ${OUTPUT} 2>&1 &
         
    docker run -d --name sysdig-node-image-analyzer \
        --privileged \
        --network host \
        -e AM_COLLECTOR_ENDPOINT=${NIA_ENDPOINT} \
        -e ACCESS_KEY=${ACCESS_KEY} \
        -v /var/run:/var/run  \
        quay.io/sysdig/node-image-analyzer:latest >> ${OUTPUT} 2>&1 &
else
    echo "ERROR: Cannot deploy Node Image Analyzer. No valid endpoint."
fi

if [ "$USE_PROMETHEUS" = true ]
then
    DOCKER_OPTS="-v ${AGENT_CONF_DIR}/prometheus.yaml:/opt/draios/etc/prometheus.yaml:rw $DOCKER_OPTS"
fi

docker run -d --name sysdig-agent \
    --restart always --privileged \
    --net host --pid host \
    -e ACCESS_KEY=${ACCESS_KEY} \
    -e COLLECTOR=${COLLECTOR} \
    -e SECURE=true \
    -e TAGS= \
    -v /var/run/docker.sock:/host/var/run/docker.sock \
    -v /dev:/host/dev \
    -v /proc:/host/proc:ro \
    -v /boot:/host/boot:ro \
    -v /lib/modules:/host/lib/modules:ro \
    -v /usr:/host/usr:ro \
    -v ${AGENT_CONF_DIR}/values.yaml:/opt/draios/etc/dragent.yaml:rw \
    ${DOCKER_OPTS} \
    --shm-size=512m \
    quay.io/sysdig/agent >> ${OUTPUT} 2>&1 &
