#!/bin/bash

kubectl get pods -A

# from step2 & 3, this is for audit logging enablement
mv kube-apiserver.pablo.yaml /etc/kubernetes/manifests/kube-apiserver.yaml

mkdir /etc/kubernetes/policies
mv ./audit-policy.yaml /etc/kubernetes/policies/audit-policy.yaml

#now the api server should be gone
kubectl get pods -A

#step 4&5, creating policies for our pods
kubectl apply -f default-psp-with-rbac.yaml
kubectl create ns sysdig-agent
kubectl apply -f privileged-psp-with-rbac.yaml
kubectl apply -f sysdig-psp-with-rbac.yaml

# now the api-server pod should be there again!
kubectl get pods -A

#installing helm 3.0 and the agent
curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm version
helm repo add sysdig https://charts.sysdig.com
helm repo update

MY_AGENT_KEY=

helm install sysdig-agent \
    --namespace sysdig-agent \
    --set sysdig.accessKey=$MY_AGENT_KEY \
    --set sysdig.settings.tags="cluster:training"  \
    --set auditLog.enabled=true \
    --set nodeAnalyzer.deploy=false \
    --set resources.requests.cpu=1 \
    --set resources.requests.memory=512Mi \
    --set resources.limits.cpu=2 \
    --set resources.limits.memory=2048Mi \
    sysdig/sysdig

#dinamyc sink
./config_audit.sh

#two sysdig pods should be already here, maybe not yet running 1/1
kubectl get pods -n sysdig-agent

#step07
kubectl create ns nginx
kubectl apply -f test-psp.yaml

#step08
echo "step-8 needs to be checked manually"

#step09
kubectl create -f nginx-deployment.yaml --namespace nginx
echo "step-9 needs to be checked manually"
