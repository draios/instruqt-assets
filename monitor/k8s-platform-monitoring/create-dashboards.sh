#!/bin/sh

APITOKEN=$1

if [ -z "$1" ]; then
  echo "This command requires the APITOKEN parameter"
  echo "Example: ./create-dashboard.sh XXXXX"
  exit 1
fi

kubectl create configmap --from-file dashboards.json sdc-dashboards

cat << EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: sdc-client-setup-dashboards
spec:
  backoffLimit: 0
  template:
    spec:
      containers:
      - name: sdc-client-setup-dashboards
        image: tembleking/sdc_client
        command: ["/sdc_client/sdc_client", "create", "dashboards", "-i", "/env_data/dashboards.json"]
        env:
        - name: SDC_TOKEN
          value: ${APITOKEN}
        volumeMounts:
        - name: sdc-dashboards
          mountPath: /env_data
      volumes:
      - name: sdc-dashboards
        configMap:
          name: sdc-dashboards
      restartPolicy: Never
EOF
