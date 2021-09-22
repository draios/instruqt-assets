#!/bin/bash

echo "This scripts generates an image of a dummy (but almost unique) app"

#generates random string
RANDOM_NEW=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 512 | head -n 1)

#generates app main
cat <<EOF >>main.py
#!/usr/bin/env python3

import time

while True:
	print("I can only print: $RANDOM_NEW")
	print("And sleep...")
	time.sleep(5)

EOF

#generates Dockerfile
cat <<EOF >>Dockerfile
FROM python:slim
COPY main.py /
CMD ["python", "./main.py" ]
EOF

#builds image
docker build -t python-test .

DIGEST=$(docker inspect python-test | jq '.[0].Id')

echo "The image has been built and its digest is: ${DIGEST}"

# build deployment
cat <<EOF >dummy-app.yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: python-test
  labels:
    name: python-test
    app: python-test
  namespace: dummy-app
spec:
  replicas: 1

  selector:
    matchLabels:
     name: python-test
     role: python-test
     app: python-test
  template:
    spec:
      tolerations: 
        - key: node-role.kubernetes.io/master
          operator: Exists
          effect: NoSchedule
      containers:
        - name: python-test
          image: python-test
          imagePullPolicy: Never
      nodeSelector:
        kubernetes.io/hostname: controlplane
    metadata:
      labels:
        name: python-test
        role: python-test
        app: python-test

EOF

# and run it
kubectl create ns dummy-app
kubectl apply -f ./dummy-app.yaml -n dummy-app

echo "The image has been deployed, check with k get pods -n dummy-app"
