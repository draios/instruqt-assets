#!/bin/bash

# Install helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash


curl -sSfL https://github.com/roboll/helmfile/releases/download/v0.134.0/helmfile_linux_amd64 -o /usr/local/bin/helmfile
chmod +x /usr/local/bin/helmfile

helmfile sync

cat << EOF
____________________________________________________________________________

Jenkins is ready!

Please click on the Jenkins tab above to access its web interface.

Username: admin
Password: $(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode)
____________________________________________________________________________

EOF
