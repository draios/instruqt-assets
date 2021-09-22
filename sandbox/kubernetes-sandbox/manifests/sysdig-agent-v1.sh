kubectl create ns sysdig-agent
kubectl create -f sysdig-account.yaml -n sysdig-agent
kubectl create -f sysdig-secret.yaml -n sysdig-agent
kubectl create configmap sysdig-agent --from-file=dragent.yaml -n sysdig-agent
kubectl create -f sysdig-daemonset-ebpf.yaml -n sysdig-agent
kubectl create -f sysdig-agent-service.yaml -n sysdig-agent
