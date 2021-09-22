#!/bin/bash

echo "Please enter your Access Key :"

# ACCESSKEY=yadayadayadayada-yadayadayada-yadayadayadayada

read ACCESSKEY

kubectl create ns sysdig-agent
kubectl create secret generic sysdig-agent --from-literal=access-key=$ACCESSKEY -n sysdig-agent
kubectl apply -f sysdig-agent-clusterrole.yaml -n sysdig-agent
kubectl create serviceaccount sysdig-agent -n sysdig-agent
kubectl create clusterrolebinding sysdig-agent --clusterrole=sysdig-agent --serviceaccount=sysdig-agent:sysdig-agent
kubectl apply -f sysdig-agent-configmap.yaml -n sysdig-agent
kubectl apply -f sysdig-agent-daemonset-v2.yaml -n sysdig-agent
