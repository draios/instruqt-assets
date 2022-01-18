#!/bin/bash
#
# Generates some cpu user load on controlplane node
#

while true; do
    sleep 30
    stress -c 1 -t 20
done