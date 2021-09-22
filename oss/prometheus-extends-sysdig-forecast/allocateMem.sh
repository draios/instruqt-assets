#!/bin/bash
#syntax allocateMem [MB_to_allocate] [time_in_minutes]

#allocates X MB of memory in files of 10MB in Y minutes

CHUNKSIZE=500

SIZE=$1
SECONDS=$(( $2 * 60 ))
REPS=$(( ${SIZE}/${CHUNKSIZE} ))
DELAY=$(( ${SECONDS}/${REPS} ))

mkdir -p trashFiles
cd trashFiles

for (( i=1; i<=${REPS}; i++ ))
    do
        echo "allocating 100MB"
        fallocate -l ${CHUNKSIZE}M    file${i} # fills memory
        #fallocate -c -l 100M file${i} in case we want to free space
        echo "sleeping $DELAY seconds"
        sleep ${DELAY} #seconds 
    done


