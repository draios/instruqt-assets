#!/bin/bash
​
set -x

#scenario preparation in Katacoda for PromQL:
#includes: metrics generator by Dmitry + Prometheus (with Dashboard)
#maybe would be interesting also including Grafana
#tested again 2020-16-01 and still worked :D
​
#scenario base: ubuntu machine 16.04 (enought with this version, it has all dependences needed)
# https://www.katacoda.com/scenario-examples/courses/environment-usages/ubuntu
​
#commands for metric simulator Dmitry
git clone https://github.com/dmitsh/promsim.git
docker run -dt --name metricSimulator -v $(pwd)/promsim:/go/promsim -p 8080:8080 golang /bin/bash
docker exec -d metricSimulator bash -c 'make -C ./promsim && ./promsim/promsim target -p 8080'
#tests raw output of the simulator on stdout
#curl localhost:8080/metrics
​
#installing prometheus
mkdir prometheus
​
touch prometheus/prometheus.yml
cat << EOT >> prometheus/prometheus.yml
# prometheus config to read simulator input
global:
  scrape_interval:     15s
  evaluation_interval: 30s
scrape_configs:
- job_name: demo
  honor_labels: true
  # scrape_interval is defined by the configured global (15s).
  # scrape_timeout is defined by the global default (10s).
  # metrics_path defaults to '/metrics'
  # scheme defaults to 'http'.
  static_configs:
  - targets: ['0.0.0.0:9091','0.0.0.0:9100','0.0.0.0:8080']
EOT
​
#run Prometheus
docker run -d -p 9090:9090 --name prometheus -v prometheus:/etc/prometheus prom/prometheus
​
#after that, select '+' > 'Select port to view on Host 1' to access service available at port 9090
echo 'select + > Select port to view on Host 1 to access service available at port 9090
