#!/bin/bash

curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
wget https://github.com/roboll/helmfile/releases/download/v0.104.0/helmfile_linux_amd64 -O /usr/local/bin/helmfile

chmod 555 /usr/local/bin/helmfile
helm repo add sysdig https://charts.sysdig.com
helm repo update
