#!/bin/bash
# debug with ctr + logs
# sudo ctr -n k8s.io containers list
# sudo cat /var/log/pods/

set -euxo pipefail

echo $(hostname -i | xargs -n1) $(hostname) >> /etc/hosts

export DEBIAN_FRONTEND=noninteractive
apt update -y 
apt install apt-transport-https ca-certificates curl software-properties-common jq -y

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc


echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update -y
apt install -y containerd.io

tee /etc/apt/sources.list.d/kubernetes.list<<EOL
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /
EOL

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
apt update -y

apt install -y kubectl kubelet kubeadm kubernetes-cni
swapoff -a
sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab

tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
# net.ipv6.conf.all.disable_ipv6 = 0
# net.ipv6.conf.default.disable_ipv6 = 0
sudo sysctl --system

mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
service containerd restart
service kubelet restart  
# systemctl status containerd
systemctl enable kubelet

kubeadm config images pull
sysctl -p
kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --apiserver-advertise-address=0.0.0.0 \
  --cri-socket unix:///run/containerd/containerd.sock


mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown $(id -u ubuntu):$(id -g ubuntu) /home/ubuntu/.kube/config
chmod 644 /home/ubuntu/.kube/config
export KUBECONFIG=/home/ubuntu/.kube/config

sudo -E -u ubuntu kubectl taint nodes --all node.kubernetes.io/not-ready-
sudo -E -u ubuntu kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# CNI
VERSION=v3.26.1
curl -O https://raw.githubusercontent.com/projectcalico/calico/${VERSION}/manifests/tigera-operator.yaml
curl -O https://raw.githubusercontent.com/projectcalico/calico/${VERSION}/manifests/custom-resources.yaml 
sudo -E -u ubuntu kubectl create -f tigera-operator.yaml
sudo -E -u ubuntu kubectl create -f custom-resources.yaml

# autocomplete https://kubernetes.io/es/docs/tasks/tools/included/optional-kubectl-configs-bash-linux/
sudo echo 'source <(kubectl completion bash)' >> ~/.bashrc
sudo echo 'source <(kubectl completion bash)' >> /home/ubuntu/.bashrc
sudo su -c 'kubectl completion bash >/etc/bash_completion.d/kubectl'
sudo echo 'alias k=kubectl' >> ~/.bashrc
sudo echo 'alias k=kubectl' >> /home/ubuntu/.bashrc
sudo echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
sudo echo 'complete -o default -F __start_kubectl k' >> /home/ubuntu/.bashrc

# deply vuln app
sudo su -c 'cat <<-"EOF" > /home/ubuntu/manifest.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: frontend
  name: frontend
  namespace: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: sysdigtraining/tomcat-front:cyberdyne-1.9
          ports:
            - containerPort: 8080
              protocol: TCP
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  labels:
    app: frontend
  namespace: frontend
spec:
  selector:
    app: frontend
  type: LoadBalancer
  externalIPs:
  - nodeipnode
  ports:
   - port: 8082
     targetPort: 8080
EOF'

sed -i "s/nodeipnode/$(curl -s http://whatismyip.akamai.com/)/g" /home/ubuntu/manifest.yaml

sudo -E -u ubuntu kubectl create ns frontend
sudo -E -u ubuntu kubectl apply -f /home/ubuntu/manifest.yaml -n frontend

# helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm repo add sysdig https://charts.sysdig.com
helm repo update


touch /home/ubuntu/userdataDONE
