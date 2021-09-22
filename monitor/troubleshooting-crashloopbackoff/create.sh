#!/bin/sh

cat <<- 'EOF' > "flask-deployment.yaml"
kind: Deployment
apiVersion: apps/v1
metadata:
  name: flask
  labels:
    name: flask-deployment
    app: nginx-crashloop
spec:
  replicas: 2
  selector:
    matchLabels:
     name: flask
     role: app
     app: nginx-crashloop
  template:
    spec:
      containers:
        - name: flask
          image: mateobur/flask
    metadata:
      labels:
        name: flask
        role: app
        app: nginx-crashloop
EOF

cat <<- 'EOF' > "nginx-deployment.yaml"
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nginx
  labels:
    name: nginx-deployment
    app: nginx-crashloop
spec:
  replicas: 0
  selector:
    matchLabels:
     name: nginx
     role: app
     app: nginx-crashloop
  template:
    spec:
      containers:
        - name: nginx
          image: nginx
          volumeMounts:
          - name: "config"
            mountPath: "/etc/nginx/nginx.conf"
            subPath: "nginx.conf"
      volumes:
        - name: "config"
          configMap:
            name: "nginxconfig"
    metadata:
      labels:
        name: nginx
        role: app
        app: nginx-crashloop
EOF


cat <<- 'EOF' > "monitorcronagent.yaml"
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: monitorcronagent-account
  namespace: nginx-flask
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: monitorcronagent-cluster-role
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]
  - nonResourceURLs: ["*"]
    verbs: ["*"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: monitorcronagent-cluster-role-binding
subjects:
  - kind: ServiceAccount
    name: monitorcronagent-account
    namespace: nginx-flask
roleRef:
  kind: ClusterRole
  name: monitorcronagent-cluster-role
  apiGroup: rbac.authorization.k8s.io
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: monitorcronagent
  namespace: nginx-flask
  labels:
    app: monitorcronagent
spec:
  replicas: 1
  selector:
    matchLabels:
     app: monitorcronagent
  template:
    spec:
      serviceAccountName: monitorcronagent-account
      containers:
        - name: monitorcronagent
          image: mateobur/nginxflaskcrash:sko
    metadata:
      labels:
        app: monitorcronagent
EOF

kubectl create namespace nginx-flask
kubectl create --namespace=nginx-flask configmap nginxconfig --from-file nginx.conf
kubectl create --namespace=nginx-flask -f flask-deployment.yaml
kubectl create --namespace=nginx-flask -f nginx-deployment.yaml
kubectl create --namespace=nginx-flask -f monitorcronagent.yaml
rm flask-deployment.yaml nginx-deployment.yaml
