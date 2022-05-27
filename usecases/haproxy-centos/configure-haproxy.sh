#!/bin/bash

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
systemctl restart haproxy
# systemctl restart haproxy
# service haproxy status
