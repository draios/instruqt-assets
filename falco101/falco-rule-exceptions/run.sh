#!/bin bash

apt install podman
apt install buildah


buildah bud -t my_app .
podman run -dt -p 8083:8080/tcp localhost/my_app


kubectl create -f app/deployment.yaml
kubectl expose deployment my_app --type=NodePort --name=my-app-svc --target-port=8081 
