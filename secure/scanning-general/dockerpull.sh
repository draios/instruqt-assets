#!/bin/bash
echo "Pulling the following containers
- learnsysdig/node:10.8.0
- learnsysdig/nginx:1.10.0
- learnsysdig/nginx:1.15.0
- learnsysdig/nginx:1.16.0
- learnsysdig/nginx:1.17.0
- learnsysdig/dummy-vuln-app
"

docker pull learnsysdig/node:10.8.0 &
docker pull learnsysdig/nginx:1.10.0 &
docker pull learnsysdig/nginx:1.15.0 &
docker pull learnsysdig/nginx:1.16.0 &
docker pull learnsysdig/nginx:1.17.0 &
docker pull learnsysdig/dummy-vuln-app &
wait
docker images | grep learnsysdig
