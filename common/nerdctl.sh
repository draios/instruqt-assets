#!/bin/bash

# no docker available in k3s labs, recommended: https://github.com/containerd/nerdctl

#this is working fine, but should be incorporated into the packer scripts
wget https://github.com/containerd/nerdctl/releases/download/v0.11.2/nerdctl-0.11.2-linux-amd64.tar.gz
tar -xvf nerdctl-0.11.2-linux-amd64.tar.gz
mv  nerdctl /usr/local/bin
# fix error default address /run/containerd/containerd.sock
# fixed namespace as all containers are in k8s.io regardless of kubernetes namespaces
echo 'alias nerdctl="nerdctl --address /run/k3s/containerd/containerd.sock --namespace k8s.io"' >> /root/.bash_aliases
source /root/.bash_aliases

# test with nerdctl ps