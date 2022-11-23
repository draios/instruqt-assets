#!/bin/bash

echo "Please enter your Access Key :"

# ACCESSKEY=yadayadayadayada-yadayadayada-yadayadayadayada

read ACCESSKEY

# ACCESSKEY="a20348b3-5496-4357-b399-8b1819b50931"
# read -e -i "$ACCESSKEY" -p "Please enter your name: " input
# ACCESSKEY="${input:-$ACCESSKEY}"


mkdir sysdig-agent
cd sysdig-agent
wget https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-agent-clusterrole.yaml
wget https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-agent-daemonset-v2.yaml
wget https://gist.githubusercontent.com/Jujuyeh/4ca189480beeeffe5dab1224e75f610f/raw/3fa2a1c128237798dcd3f59de29e103f12bc8392/sysdig-agent-configmap.yaml
# wget https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-agent-configmap.yaml
cd ..

kubectl create ns sysdig-agent
kubectl create secret generic sysdig-agent --from-literal=access-key=$ACCESSKEY -n sysdig-agent
kubectl apply -f sysdig-agent/sysdig-agent-clusterrole.yaml -n sysdig-agent
kubectl create serviceaccount sysdig-agent -n sysdig-agent
kubectl create clusterrolebinding sysdig-agent --clusterrole=sysdig-agent --serviceaccount=sysdig-agent:sysdig-agent

kubectl apply -f sysdig-agent/sysdig-agent-configmap.yaml -n sysdig-agent
kubectl apply -f sysdig-agent/sysdig-agent-daemonset-v2.yaml -n sysdig-agent
