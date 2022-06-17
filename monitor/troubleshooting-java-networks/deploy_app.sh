#!/bin/bash
  
kubectl create ns example-java-app

for app in "cassandra.yaml" "mongo.yaml" "redis.yaml"; do
  kubectl apply -f example-java-app/$app -n example-java-app
done

until test $(kubectl get pods -n example-java-app | grep -cE "1/1\s+Running") == "3"; do
  sleep 1
done

kubectl apply -f example-java-app/java-client.yaml -n example-java-app
kubectl apply -f example-java-app/javaapp.yaml -n example-java-app

kubectl expose deployment javaapp \
  --type=LoadBalancer \
  --port 8080 \
  --name=java-app-svc \
  -n example-java-app
