#!/bin/bash


mkdir psql-exporter
cd psql-exporter

cat <<-"EOF" > ./values.yaml
dbInstance:
  database: postgres
  host: db 
  port: "5432"
  sslRootCertEnabled: false
  sslmode: disable
exporterNamespaceName: lab2-example-voting-app
exporterParams:
  autoDiscoverDatabases: true
namespaceName: lab2-example-voting-app
secretName: postgresql-exporter
workloadName: db
workloadType: deployment
EOF

kubectl create -n postgres secret generic postgresql-exporter \
  --from-literal=username=postgres_exporter \
  --from-literal=password=password

helm install -n postgres -f values.yaml --repo https://sysdiglabs.github.io/integrations-charts sysdigcloud-sysdigcloud-postgresql12 postgresql-exporter