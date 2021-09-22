#!/bin/sh

kubectl scale -n example-voting-app --replicas=15 deployment/voter
