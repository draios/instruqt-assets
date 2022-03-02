#!/bin/sh

pushd /root/assets/
helmfile sync
kubectl apply -f complete-sock-shop.yaml -n sock-shop
popd
