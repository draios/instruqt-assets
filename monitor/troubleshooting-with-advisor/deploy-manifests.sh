#!/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl create ns application
kubectl create ns stress-test
kubectl create ns stress-test-cpu
kubectl label node worker1 dedicated=test
kubectl create ns distributed-db

kubectl apply -f ${DIR}/manifests/
sleep 5
kubectl apply -f ${DIR}/manifests/db-monitor/
