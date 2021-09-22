#!/bin/bash

x=0
echo -n "|"
while [ $x -le 100 ]
do
  curl -s localhost:8000 > /dev/null
  x=$(( $x + 1 ))
  echo -n "."
done 

echo "|"