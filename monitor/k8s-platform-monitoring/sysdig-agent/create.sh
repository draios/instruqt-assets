#!/bin/sh

AGENTKEY=$1
TAGS=$2
CLUSTER_NAME=$3

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]
then
	echo "This command requires three parameters: AGENTKEY, TAGS and CLUSTER_NAME"
	echo "Example: ./create.sh XXXXX cluster:training training-cluster"
	exit 1
fi

if kubectl get nodes | grep ^gke > /dev/null
then
  echo "This looks like a GKE cluster, making yourself cluster-admin first."
  kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user $(gcloud config get-value account)
fi

NAMESPACE="sysdig-agent-kubernetes-internal"
kubectl create namespace ${NAMESPACE}

#ETCD_POD=$(kubectl get pod -n kube-system | grep ^etcd-server-ip | cut -f1 -d ' ')

#kubectl exec -n kube-system ${ETCD_POD} cat /srv/kubernetes/etcd.pem > client-cert
#kubectl exec -n kube-system ${ETCD_POD} cat /srv/kubernetes/etcd-key.pem > client-key

#kubectl -n ${NAMESPACE} create secret generic etcd \
#	--from-file=client-cert  \
#	--from-file=client-key

#rm client-cert client-key

kubectl -n ${NAMESPACE} create secret generic etcd --from-file=../etcd/client-cert --from-file=../etcd/client-key

cp sysdig-secret.yaml sysdig-secret.yaml.dist
H_AGENTKEY=`echo -n "$AGENTKEY" | base64`
sed -i.bak "s/  access-key:/  access-key: \"$H_AGENTKEY\"/" sysdig-secret.yaml
rm sysdig-secret.yaml.bak

cp dragent.yaml dragent.yaml.dist
sed -i.bak "s/tags:/tags: \"$TAGS\"/" dragent.yaml
sed -i.bak "s/k8s_cluster_name:/k8s_cluster_name: \"$CLUSTER_NAME\"/" dragent.yaml
rm dragent.yaml.bak

cp sysdig-account.yaml sysdig-account.yaml.dist
sed -i.bak "s/    namespace:/    namespace: \"$NAMESPACE\"/" sysdig-account.yaml
rm sysdig-account.yaml.bak

kubectl -n ${NAMESPACE} create -f sysdig-account.yaml
kubectl -n ${NAMESPACE} create -f sysdig-secret.yaml
kubectl -n ${NAMESPACE} create configmap sysdig-agent-config --from-file=dragent.yaml=dragent.yaml
kubectl -n ${NAMESPACE} create -f sysdig-daemonset.yaml

mv sysdig-secret.yaml.dist sysdig-secret.yaml
mv dragent.yaml.dist dragent.yaml
mv sysdig-account.yaml.dist sysdig-account.yaml
