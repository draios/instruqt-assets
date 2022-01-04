#!/bin/bash
echo "Pulling the following containers
- learnsysdig/node:10.8.0
- learnsysdig/nginx:1.10.0
- learnsysdig/nginx:1.15.0
- learnsysdig/nginx:1.16.0
- learnsysdig/nginx:1.17.0
- learnsysdig/dummy-vuln-app
"

podman pull learnsysdig/node:10.8.0 &
podman pull learnsysdig/nginx:1.10.0 &
podman pull learnsysdig/nginx:1.15.0 &
podman pull learnsysdig/nginx:1.16.0 &
podman pull learnsysdig/nginx:1.17.0 &
podman pull learnsysdig/dummy-vuln-app &
wait
podman images | grep learnsysdig
