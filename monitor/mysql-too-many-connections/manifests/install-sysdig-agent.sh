#!/bin/bash

echo "Please enter your Access Key :"

# ACCESSKEY=yadayadayadayada-yadayadayada-yadayadayadayada

read ACCESSKEY

# kubectl create ns sysdig-agent
# kubectl create secret generic sysdig-agent --from-literal=access-key=$ACCESSKEY -n sysdig-agent
# kubectl apply -f sysdig-agent-clusterrole.yaml -n sysdig-agent
# kubectl create serviceaccount sysdig-agent -n sysdig-agent
# kubectl create clusterrolebinding sysdig-agent --clusterrole=sysdig-agent --serviceaccount=sysdig-agent:sysdig-agent
# kubectl apply -f sysdig-agent-configmap.yaml -n sysdig-agent
# kubectl apply -f sysdig-agent-daemonset-v2.yaml -n sysdig-agent

apt-get -y install linux-headers-$(uname -r)

docker run -d --name sysdig-agent --restart always --privileged --net host --pid host -e ACCESS_KEY=$ACCESSKEY -e SECURE=true -e TAGS=example_tag:example_value -v /var/run/docker.sock:/host/var/run/docker.sock -v /dev:/host/dev -v /proc:/host/proc:ro -v /boot:/host/boot:ro -v /lib/modules:/host/lib/modules:ro -v /usr:/host/usr:ro --shm-size=512m sysdig/agent
