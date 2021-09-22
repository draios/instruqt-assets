#!/bin/sh
kubectl delete -f sink.yaml
AGENT_SERVICE_CLUSTERIP=$(kubectl get service sysdig-agent -o=jsonpath={.spec.clusterIP} -n sysdig-agent) envsubst < sink.yaml.in > sink.yaml
kubectl create -f sink.yaml
