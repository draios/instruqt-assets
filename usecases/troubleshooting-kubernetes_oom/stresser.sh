#!/bin/bash

# Set stress settings. See https://hub.docker.com/r/progrium/stress/
STRESSCMD="stress --cpu 8 --io 4 --vm 2 --vm-bytes 128M --timeout 10s"

# Get pod name
STRESSPOD=$(kubectl get pods -n example-voting-app |grep stresser | awk '{print $1}')

# Run stress commands
kubectl exec $STRESSPOD -n example-voting-app -- $STRESSCMD
