#!/bin/sh

NAMESPACE="sysdig-agent-kubernetes-internal"

kubectl delete clusterrole sysdig-cluster-role
kubectl delete clusterrolebinding sysdig-cluster-role-binding
kubectl delete namespace ${NAMESPACE}
