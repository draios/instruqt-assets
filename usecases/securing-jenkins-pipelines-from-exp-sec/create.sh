#!/bin/bash

# Ensure k8s is running. Something like this
# 
# while[ !$(kubectl cluster-info) ; do
# echo "Waiting for cluster"
# sleep 2
# done

# Install helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

curl -sSfL https://github.com/roboll/helmfile/releases/download/v0.98.3/helmfile_linux_amd64 -o /usr/local/bin/helmfile
chmod +x /usr/local/bin/helmfile

helmfile sync --concurrency 1

cat << EOF
____________________________________________________________________________

Jenkins is ready!

Please click on the Jenkins tab above to access its web interface.

Username: admin
Password: $(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode)
____________________________________________________________________________


Deploying Sysdig Agent...

EOF

bash ./install_sysdig-agent.sh
