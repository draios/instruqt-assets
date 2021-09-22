#!/bin/bash

wget https://github.com/prometheus/node_exporter/releases/download/v0.14.0/node_exporter-0.14.0.linux-amd64.tar.gz
tar -xzf node_exporter-*.linux-amd64.tar.gz
cd node_exporter-*.linux-amd64
./node_exporter &
