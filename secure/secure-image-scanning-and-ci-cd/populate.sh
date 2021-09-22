#!/bin/sh

POD_NAME=`kubectl get pods -n jenkins | grep jenkins | awk '{print $1}'`
ADMIN_PASSWD=`kubectl exec -n jenkins $POD_NAME -- cat /var/jenkins_home/secrets/initialAdminPassword`
JENKINS_HOME="/var/jenkins_home"

K="kubectl exec -n jenkins $POD_NAME -- "

$K rm -rf $JENKINS_HOME/plugins/ $JENKINS_HOME/jobs/
$K tar xvf jobs.tar.gz -C $JENKINS_HOME/
$K tar xvf plugins.tar.gz -C $JENKINS_HOME/
$K java -jar $JENKINS_HOME/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/ -auth admin:$ADMIN_PASSWD restart

