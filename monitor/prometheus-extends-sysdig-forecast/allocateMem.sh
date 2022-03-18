#!/bin/bash

#######
#  Allocates X MB of memory in files of 10MB in Y minutes
#######

if [ -z $1 ] || [ -z $2 ]; then
  echo "usage: $0 <mb_to_allocate> <time_in_minutes>"
  exit 1
fi

# wait for the agent to be running
if [ ! -z $3 ]; then
  until (kubectl get pods -n sysdig-agent | grep Running | grep 1/1)
  do sleep 1;
  done
fi

CHUNKSIZE=10

SIZE=$1
SECONDS=$(( $2 * 60 ))
REPS=$(( ${SIZE}/${CHUNKSIZE} ))
DELAY=$(( ${SECONDS}/${REPS} ))

FOLDER=/opt/sysdig/memFiles-`date +%Y-%m-%d-%H-%M`
mkdir -p $FOLDER
cd $FOLDER

for (( i=1; i<=${REPS}; i++ ))
do
  echo "allocating $(( ${i}*${CHUNKSIZE} ))MB of ${SIZE}MB"
  fallocate -l ${CHUNKSIZE}M    file${i} # fills memory
  #fallocate -c -l 100M file${i} in case we want to free space
  echo "sleeping $DELAY seconds"
  sleep ${DELAY} #seconds
done
