
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
            echo "Region $opt selected, collector set to https://ingest-us2.app.sysdig.com"
            break
            ;;
        "EMEA")
            MY_REGION_COLLECTOR='ingest-eu1.app.sysdig.com'
            echo "Region $opt selected, collector set to https://ingest-eu1.app.sysdig.com"
            break
            ;;
        "Abort")
            exit 1
            ;;
        *) echo "Not an option: $REPLY. Select one of the following";;
    esac
done

sed -i "s/    # collector: 192.168.1.1/    collector: $MY_REGION_COLLECTOR/g" sysdig-agent-configmap.yaml
sed -i "s/    # collector_port: 6666/    collector_port: 6443/g" sysdig-agent-configmap.yaml


kubectl create ns sysdig-agent
kubectl create secret generic sysdig-agent --from-literal=access-key=$ACCESSKEY -n sysdig-agent
kubectl apply -f sysdig-agent-clusterrole.yaml -n sysdig-agent
kubectl create serviceaccount sysdig-agent -n sysdig-agent
kubectl create clusterrolebinding sysdig-agent --clusterrole=sysdig-agent --serviceaccount=sysdig-agent:sysdig-agent
kubectl apply -f sysdig-agent-configmap.yaml -n sysdig-agent
kubectl apply -f sysdig-agent-daemonset-v2.yaml -n sysdig-agent

