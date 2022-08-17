#!/bin/bash

POD_NAME=`kubectl get pod -n nginx-flask | grep monitor | cut -d' ' -f 1`
echo "Triggering sporadic pod restarts, this will take a few minutes..."
kubectl exec -it $POD_NAME -n nginx-flask -- /bin/sed -i 's/7/3/g' /root/nginx-crashloop.sh
kubectl exec -it $POD_NAME -n nginx-flask /root/nginx-crashloop.sh
