#!/bin/bash

while true ; do
  # pick a node
  nodes[0]="server"
  nodes[1]="worker1"
  rand=$[ $RANDOM % 2 ]
  TARGETNODE=${nodes[$rand]}

  echo "kubelet restarting on node \"$TARGETNODE\""
  ssh $TARGETNODE 'systemctl restart kubelet'

  SLEEPYTIME=$(( ( RANDOM % 8 )  + 1 ))
  echo "Sleeping for $SLEEPYTIME seconds"
  sleep $SLEEPYTIME
  echo ""
done
