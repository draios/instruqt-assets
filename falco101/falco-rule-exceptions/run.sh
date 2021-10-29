#!/bin bash
# git clone https://github.com/draios/instruqt-assets.git
cp -r /root/instruqt-assets/falco101/falco-rule-exceptions/* /root/
rm -rf instruqt-assets/

apt install podman buildah -y

buildah bud -t my_app /root./app
# podman run -dt -p 8083:8080/tcp localhost/my_app
podman save -o image.tar  localhost/my_app
k3s ctr images import image.tar

kubectl create -f app/deployment.yaml

kubectl expose deployment my_app --type=NodePort --name=my-app-svc --target-port=8081 
