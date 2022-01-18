#!/bin/bash

x=0
while [ $x -le 612 ]
do
  curl localhost:8001
  if [ $(( $x % 2 )) -eq 0 ]; then
  	curl localhost:8002
  fi
  x=$(( $x + 1 ))
  echo "$x"
done 