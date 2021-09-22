#!/bin/bash

source .reponame

docker push $REPONAME/node:10.8.0
docker push $REPONAME/nginx:1.10.0
docker push $REPONAME/nginx:1.15.0
docker push $REPONAME/nginx:1.16.0
docker push $REPONAME/nginx:1.17.0
docker push $REPONAME/dummy-vuln-app
# docker push $REPONAME/python:2.7.17
