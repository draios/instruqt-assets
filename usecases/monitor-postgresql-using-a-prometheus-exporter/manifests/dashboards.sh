#!/bin/bash

echo "Please enter your Monitor API Key :"
read APIKEY

docker  run -it --rm \
    sysdiglabs/promcat-connect:0.1 \
    install \
    postgresql:<=12\
    -t ${APIKEY}
