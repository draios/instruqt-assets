#!/bin/sh

cd /root/assets/
helmfile sync
kubectl apply -f complete-sock-shop.yaml -n sock-shop
cd /root
