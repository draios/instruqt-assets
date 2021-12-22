#!/usr/bin/env bash
##
# Deploy a Sysdig Agent directly in the host.
#
# Usage:
#   install_with_host.sh ${CLUSTER_NAME} ${ACCESS_KEY} ${COLLECTOR}
##

CLUSTER_NAME=$1
ACCESS_KEY=$2
COLLECTOR=$3

if [ "$USE_NODE_ANALYZER" = true ]
then
    echo "WARNING: Ignoring Node Analyzer option."
fi

if [ "$USE_NODE_IMAGE_ANALYZER" = true ]
then

    echo "WARNING: Ignoring Node Image Analyzer option."
fi

if [ "$USE_PROMETHEUS" = true ]
then
    HOST_OPTS="--aditional_conf \"prometheus:\\n    enabled: true\" ${HOST_OPTS}"
fi

curl -s https://download.sysdig.com/stable/install-agent | sudo bash -s -- \
    --access_key ${ACCESS_KEY} \
    --collector ${COLLECTOR} \
    --secure true \
    ${HOST_OPTS} >> /opt/sysdig/host_install.out 2>&1 &
