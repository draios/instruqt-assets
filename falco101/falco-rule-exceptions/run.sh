#!/bin bash
# git clone https://github.com/draios/instruqt-assets.git
# cp -r /root/instruqt-assets/falco101/falco-rule-exceptions/* /root/
# rm -rf instruqt-assets/

apt-get install curl wget gnupg2 -y
source /etc/os-release
sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key -O- | apt-key add -
apt-get update -qq -y
# apt-get -qq --yes install podman
apt install podman buildah -y

buildah bud -t my_app /root/app
# podman run -dt -p 8083:8080/tcp localhost/my_app
podman save -o image.tar  localhost/my_app
k3s ctr images import image.tar


helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
kubectl create ns falco
helm install falco -n falco falcosecurity/falco

kubectl create -f app/deployment.yaml

# kubectl expose deployment my_app --type=NodePort --name=my-app-svc --target-port=8081 

kubectl logs --selector app=falco -n falco

# docker build -t sysdigtraining/shell_runner .
# docker push sysdigtraining/shell_runner 