#!/bin/bash
# debug with ctr + logs
# ctr -n k8s.io containers list
# cat /var/log/pods/

set -euxo pipefail

echo $(hostname -i | xargs -n1) $(hostname) >> /etc/hosts
# avoid apt promt
sed -i "s/'i'/'a'/g" /etc/needrestart/needrestart.conf

export DEBIAN_FRONTEND=noninteractive
apt update -y

apt install -y apt-transport-https ca-certificates curl software-properties-common jq python3-pip nmap unzip

sudo su -l ubuntu -c '
  pip uninstall awscli -y
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip &> /dev/null
  sudo ./aws/install
  hash  -r
  rm -rf /home/ubuntu/awscliv2.zip /home/ubuntu/aws
  echo "alias aws='/usr/local/bin/aws'" >> /home/ubuntu/.bashrc
  PIP_BREAK_SYSTEM_PACKAGES=1 pip3 install pyopenssl --upgrade
  # install uv + pacu (isolated venv, pacu on PATH)
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="/home/ubuntu/.local/bin:$PATH"
  echo "export PATH=\"/home/ubuntu/.local/bin:\$PATH\"" >> /home/ubuntu/.bashrc
  uv tool install pacu
'

# icon and hostname
set +u
cp /home/ubuntu/.bashrc /home/ubuntu/.bashrc.backup
echo "PS1='🦠 \[\e]0;\u@\h: \w\a\]\[\033[01;32m\]attacker@host\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /home/ubuntu/.bashrc
source /home/ubuntu/.bashrc
set -u

# remove welcome message
sed -i "/^session[[:space:]]\+optional[[:space:]]\+pam_motd.so/ s/^/#/" /etc/pam.d/sshd && sudo systemctl restart ssh

# cat <<\EOF >> /home/ubuntu/.profile
# enable -n exit
# enable -n enable
# trap '' 2
# EOF

touch /home/ubuntu/userdataDONE
