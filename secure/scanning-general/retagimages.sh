#!/bin/bash

echo "Please enter your repository name (this is your Docker Hub 'user') :"

read REPONAME
echo "REPONAME=$REPONAME" > ./.reponame

docker tag learnsysdig/node:10.8.0 $REPONAME/node:10.8.0
docker tag learnsysdig/nginx:1.10.0 $REPONAME/nginx:1.10.0
docker tag learnsysdig/nginx:1.15.0 $REPONAME/nginx:1.15.0
docker tag learnsysdig/nginx:1.16.0 $REPONAME/nginx:1.16.0
docker tag learnsysdig/nginx:1.17.0 $REPONAME/nginx:1.17.0
docker tag learnsysdig/dummy-vuln-app $REPONAME/dummy-vuln-app
#docker tag learnsysdig/python-app:0.1.0 $REPONAME/python-app:0.1.0
#docker tag learnsysdig/java-app:0.1.0 $REPONAME/java-app:0.1.0


echo "Images retagged"
echo ""
docker images | grep $REPONAME
