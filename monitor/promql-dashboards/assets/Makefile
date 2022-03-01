CLUSTER_NAME=demo-kube-aws
SSH_USER=admin
PRIVATE_KEY_PATH=~/.ssh/marketing-infra.pem

BASTION=$(shell aws elb describe-load-balancers --region us-east-1 | jq -r ".LoadBalancerDescriptions[] | select(.LoadBalancerName | index(\"$(CLUSTER_NAME)\")) | select(.ListenerDescriptions[].Listener.LoadBalancerPort == 22) | .DNSName")
SSH_OPTS=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
SSH_PROXY_COMMAND=ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p -i $(PRIVATE_KEY_PATH) $(SSH_USER)@$(BASTION)
MASTERS=$(shell KUBECONFIG=kubeconfig kubectl get nodes -o json | jq -r '.items[] | select(.metadata.labels["kubernetes.io/role"]=="master") | .status.addresses[] | select(.type == "InternalIP") | .address')
NODES=$(shell KUBECONFIG=kubeconfig kubectl get nodes -o json | jq -r '.items[] | select(.metadata.labels["kubernetes.io/role"]=="node") | .status.addresses[] | select(.type == "InternalIP") | .address')

kubeconfig:
	KUBECONFIG=kubeconfig kops export kubecfg --name demo-kube-aws.k8s.local --state s3://demo-environments-state/kops

ssh:
	ssh \
	  -i $(PRIVATE_KEY_PATH) \
	  $(SSH_OPTS) \
	  -o ProxyCommand="$(SSH_PROXY_COMMAND)" \
	  $(SSH_USER)@${IP}

inventory: kubeconfig
	> $@
	@echo [all:vars] >> $@
	@echo ansible_user=$(SSH_USER) >> $@
	@echo ansible_ssh_private_key_file=$(PRIVATE_KEY_PATH) >> $@
	@echo ansible_ssh_common_args='$(SSH_OPTS)' >> $@
	@echo ansible_python_interpreter=/usr/bin/python >> $@
	@echo [bastion] >> $@
	@echo $(BASTION) >> $@
	@echo [masters] >> $@
	@for master in $(MASTERS); do \
	  echo $$master >> $@; \
	  done
	@echo [nodes] >> $@
	@for node in $(NODES); do \
	  echo $$node >> $@; \
	  done
	@echo [hidden:children] >> $@
	@echo masters >> $@
	@echo nodes >> $@
	@echo [hidden:vars] >> $@
	@echo ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="$(SSH_PROXY_COMMAND)"' >> $@

enable-audit-log: inventory
	ansible-playbook -i inventory -b enable-audit-log.yaml

sync: kubeconfig
	KUBECONFIG=kubeconfig helmfile sync
