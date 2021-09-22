#!/bin/bash

show_progress()
{
  echo -n "Your environment is being prepared..."
  echo ""
  
  local -r pid="${1}"
  local -r delay='0.75'
  local spinstr='\|/-'
  local temp

  echo -n "[1/2] Waiting for K8s cluster to be ready"
  while true; do 
    sudo grep -i "k8sReady" /root/katacoda-process  &> /dev/null
    if [[ "$?" -ne 0 ]]; then     
      temp="${spinstr#?}"
      printf " [%c]  " "${spinstr}"
      spinstr=${temp}${spinstr%"${temp}"}
      sleep "${delay}"
      printf "\b\b\b\b\b\b"
    else
      break
    fi
  done
  printf "    \b\b\b\b"
  echo ""  

  echo -n "[2/2] Deploying example-voting-app"
  while true; do 
    sudo grep -i "voting-app" /root/katacoda-process  &> /dev/null
    if [[ "$?" -ne 0 ]]; then     
      temp="${spinstr#?}"
      printf " [%c]  " "${spinstr}"
      spinstr=${temp}${spinstr%"${temp}"}
      sleep "${delay}"
      printf "\b\b\b\b\b\b"
    else
      break
    fi
  done
  printf "    \b\b\b\b"
  echo ""  

  echo "The environment is ready!"
}

show_progress
