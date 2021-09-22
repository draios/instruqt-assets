#!/bin/bash

wget https://github.com/containerd/nerdctl/releases/download/v0.11.2/nerdctl-0.11.2-linux-amd64.tar.gz
tar -xvf nerdctl-0.11.2-linux-amd64.tar.gz
mv  nerdctl /usr/local/bin

