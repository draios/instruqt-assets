#!/bin/bash

echo "Please enter your repository name (this is your Docker Hub 'user') :"

read REPONAME
echo "REPONAME=$REPONAME" > ./.reponame

podman tag learnsysdig/node:10.8.0    docker.io/$REPONAME/node:10.8.0
podman tag learnsysdig/nginx:1.10.0   docker.io/$REPONAME/nginx:1.10.0
podman tag learnsysdig/nginx:1.15.0   docker.io/$REPONAME/nginx:1.15.0
podman tag learnsysdig/nginx:1.16.0   docker.io/$REPONAME/nginx:1.16.0
podman tag learnsysdig/nginx:1.17.0   docker.io/$REPONAME/nginx:1.17.0
podman tag learnsysdig/dummy-vuln-app docker.io/$REPONAME/dummy-vuln-app

echo "Images retagged"
echo ""
podman images | grep $REPONAME
