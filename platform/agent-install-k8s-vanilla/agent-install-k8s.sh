#!/bin/bash

echo "Sysdig Agent install script for a k8s cluster using Helm"
echo 
read -p "Please enter your Sysdig Key :" ACCESSKEY
echo 
echo "Select region to define collector address :"
PS3='Please select one of the options above (type name or number): '
options=("US East (default)" "US West" "EMEA" "Abort install")
select opt in "${options[@]}"
do
    case $opt in
        "US East (default)")
            COLLECTOR_ADDRESS='collector.sysdigcloud.com'
            echo "Region $opt selected, collector set to collector.sysdigcloud.com"
            break
            ;;
        "US West")
            COLLECTOR_ADDRESS='ingest-us2.app.sysdig.com'
            echo "Region $opt selected, collector set to https://ingest-us2.app.sysdig.com"
            break
            ;;
        "EMEA")
            COLLECTOR_ADDRESS='ingest-eu1.app.sysdig.com'
            echo "Region $opt selected, collector set to https://ingest-eu1.app.sysdig.com"
            break
            ;;
        "Abort")
            exit 1
            ;;
        *) echo "Not an option: $REPLY. Select one of the following";;
    esac
done

mkdir sysdig-agent
cd sysdig-agent
wget https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-agent-clusterrole.yaml
wget https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-agent-daemonset-v2.yaml
wget https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-agent-configmap.yaml
wget https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-image-analyzer-daemonset.yaml
wget https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-image-analyzer-configmap.yaml

cd ..

sed -i "s/# collector: 192.168.1.1/collector: $COLLECTOR_ADDRESS/g" sysdig-agent/sysdig-agent-configmap.yaml
sed -i "s/# collector_port: 6666/ collector_port: 6443/g" sysdig-agent/sysdig-agent-configmap.yaml


# create resources
kubectl create secret generic sysdig-agent --from-literal=access-key=$ACCESSKEY -n sysdig-agent
kubectl apply -f sysdig-agent/sysdig-agent-clusterrole.yaml -n sysdig-agent
kubectl create serviceaccount sysdig-agent -n sysdig-agent
kubectl create clusterrolebinding sysdig-agent --clusterrole=sysdig-agent --serviceaccount=sysdig-agent:sysdig-agent
kubectl apply -f sysdig-agent/sysdig-agent-configmap.yaml -n sysdig-agent
kubectl apply -f sysdig-agent/sysdig-agent-daemonset-v2.yaml -n sysdig-agent

kubectl apply -f sysdig-agent/sysdig-image-analyzer-daemonset.yaml -n sysdig-agent
kubectl apply -f sysdig-agent/sysdig-image-analyzer-configmap.yaml -n sysdig-agent
