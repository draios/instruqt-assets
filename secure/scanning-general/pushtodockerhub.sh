#!/bin/bash

source .reponame

podman push $REPONAME/node:10.8.0
podman push $REPONAME/nginx:1.10.0
podman push $REPONAME/nginx:1.15.0
podman push $REPONAME/nginx:1.16.0
podman push $REPONAME/nginx:1.17.0
podman push $REPONAME/dummy-vuln-app
