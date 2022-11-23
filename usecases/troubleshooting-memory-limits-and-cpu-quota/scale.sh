#!/bin/sh

kubectl scale -n example-voting-app --replicas=3 deployment/vote
