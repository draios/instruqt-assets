#!/bin/sh

NAMESPACE="example-java-app"
TIME_TO_SLEEP=30

start_application() {
  echo -n "\nStarting application on ${NAMESPACE} namespace\n\n"
  kubectl create namespace ${NAMESPACE}
  kubectl -n ${NAMESPACE} apply -f example-java-app/
  sleep ${TIME_TO_SLEEP}
}

stop_application() {
  echo -n "\nDeleting application on ${NAMESPACE} namespace\n\n"
  kubectl -n ${NAMESPACE} delete -f example-java-app/
  kubectl delete namespace ${NAMESPACE}
  sleep ${TIME_TO_SLEEP}
}

while :
do
  start_application
  stop_application
done
