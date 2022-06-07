#!/bin/bash
count=0
EXTERNALIP=`kubectl get services -n example-java-app |grep java-app-svc | awk '{print $4}'`
while true
do
  echo count: $count
  ab -t 60 -n 10000000 -c 500 -s 1 http://$EXTERNALIP:8080/
  ((count=count+1))
done