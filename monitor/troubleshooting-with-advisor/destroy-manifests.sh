#!/bin/env bash

kubectl delete pods --all -n stress-test-cpu
kubectl delete pods --all -n stress-test
kubectl delete deployments --all -n application

kubectl delete ns application
kubectl delete ns stress-test
kubectl delete ns stress-test-cpu
