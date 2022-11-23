#!/bin/sh

kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/db.yaml
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/observer.yaml
kubectl apply -f manifests/redis.yaml
kubectl apply -f manifests/result.yaml
kubectl apply -f manifests/vote.yaml
kubectl apply -f manifests/voter.yaml
kubectl apply -f manifests/worker.yaml
