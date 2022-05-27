#!/bin/bash

yum install haproxy -y
# mkdir -p /run/haproxy/

cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.0

cat <<- 'EOF' > "/etc/haproxy/haproxy.cfg"
global
    log         127.0.0.1 local2

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

    stats socket /var/lib/haproxy/stats

defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

frontend  main *:5000
    acl url_static       path_beg       -i /static /images /javascript /stylesheets
    acl url_static       path_end       -i .jpg .gif .png .css .js

    default_backend             app

backend app
    balance     roundrobin
#    server app2 2886795273-8443-frugo02.environments.katacoda.com:80 check
EOF

echo "How many items are in your load blancing pool?"
read NUMBERCLUSTERS

for i in `seq 1 $NUMBERCLUSTERS` ; do
  echo "Please enter item $i to be load balanced:"
  read OCP
  echo "    server app$i $OCP:80 check" >> /etc/haproxy/haproxy.cfg
done

echo "The following line have been added to '/etc/haproxy/haproxy.cfg' file"
echo ""

tail -$NUMBERCLUSTERS /etc/haproxy/haproxy.cfg

# cat /etc/haproxy/haproxy.cfg
# haproxy -db -f /etc/haproxy/haproxy.cfg


systemctl enable haproxy
systemctl start haproxy
# systemctl restart haproxy
service haproxy status
