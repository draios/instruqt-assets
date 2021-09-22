#!/bin/sh
# https://suraj.io/post/apiserver-in-minikube-static-configs/
# https://evalle.xyz/posts/configure-kube-apiserver-in-minikube/
# alternative would be to hack this template /etc/kubernetes/manifests/kube-apiserver.yaml
mkdir -p $HOME/.minikube/files/var/lib/minikube/certs/files
cp audit-policy.yaml $HOME/.minikube/files/var/lib/minikube/certs/files
#cp audit-webhook.yaml $HOME/.minikube/files/etc/kubernetes/addons/
/home/bencer/bin/minikube start --v=5 \
	--vm-driver=none --extra-config=kubelet.resolv-conf=/run/systemd/resolve/resolv.conf \
	--feature-gates="AppArmor=true,DynamicAuditing=true" \
	--extra-config=apiserver.enable-admission-plugins="NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,NodeRestriction,ResourceQuota,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,PodSecurityPolicy" \
	--extra-config=apiserver.audit-policy-file=/var/lib/minikube/certs/files/audit-policy.yaml \
	--extra-config=apiserver.audit-log-path=- \
	--extra-config=apiserver.audit-dynamic-configuration=true \
	--extra-config=apiserver.runtime-config=auditregistration.k8s.io/v1alpha1

#kubectl apply -f default-psp-with-rbac.yaml
#kubectl apply -f privileged-psp-with-rbac.yaml

# using vm-driver=none as sysdig-agent doesnt work now on minikube
# https://sysdig.atlassian.net/browse/SMAGENT-2091
# sshd and kubeadm required on the host

# for static webhook config use:
#	  --extra-config=apiserver.audit-webhook-config-file=/etc/kubernetes/local/audit-webhook.yaml \
# to troubleshoot apiserver use:
# minikube ssh 'docker logs $(docker ps -a -f name=k8s_kube-api --format={{.ID}})'
