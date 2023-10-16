#!/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl create ns application
kubectl create ns stress-test
kubectl create ns stress-test-cpu

kubectl apply -f ${DIR}/manifests/