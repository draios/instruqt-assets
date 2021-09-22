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
            MY_REGION_COLLECTOR='collector.sysdigcloud.com'
            echo "Region $opt selected, collector set to collector.sysdigcloud.com"
            break
            ;;
        "US West")
            MY_REGION_COLLECTOR='ingest-us2.app.sysdig.com'
            echo "Region $opt selected, collector set to ingest-us2.app.sysdig.com"
            break
            ;;
        "EMEA")
            MY_REGION_COLLECTOR='ingest-eu1.app.sysdig.com'
            echo "Region $opt selected, collector set to ingest-eu1.app.sysdig.com"
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
#wget https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-agent-configmap.yaml
wget https://raw.githubusercontent.com/sysdiglabs/promcat-resources/master/resources/postgresql/include/sysdig-agent-config.yaml
wget https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-image-analyzer-daemonset.yaml
wget https://raw.githubusercontent.com/draios/sysdig-cloud-scripts/master/agent_deploy/kubernetes/sysdig-image-analyzer-configmap.yaml


cd ..

#sed -i "s/# collector: 192.168.1.1/collector: $MY_REGION_COLLECTOR/g" sysdig-agent-configmap.yaml
#sed -i "s/# collector_port: 6666/ collector_port: 6443/g" sysdig-agent-configmap.yaml
sed -i "4i\ \ \ \ customerid: $ACCESSKEY" sysdig-agent/sysdig-agent-config.yaml
sed -i "4i\ \ \ \ collector: $MY_REGION_COLLECTOR" sysdig-agent/sysdig-agent-config.yaml
sed -i "5i\ \ \ \ collector_port: 6443" sysdig-agent/sysdig-agent-config.yaml

# agent
kubectl create ns sysdig-agent

kubectl create secret generic sysdig-agent --from-literal=access-key=$ACCESSKEY -n sysdig-agent
kubectl apply -f sysdig-agent/sysdig-agent-clusterrole.yaml -n sysdig-agent
kubectl create serviceaccount sysdig-agent -n sysdig-agent
kubectl create clusterrolebinding sysdig-agent --clusterrole=sysdig-agent --serviceaccount=sysdig-agent:sysdig-agent
kubectl apply -f sysdig-agent/sysdig-agent-config.yaml -n sysdig-agent
kubectl apply -f sysdig-agent/sysdig-agent-daemonset-v2.yaml -n sysdig-agent
