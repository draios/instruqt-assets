#!/bin/bash

# copy the current nginx config (it will be used later)
cp /etc/nginx/nginx.conf /root/nginx.conf

# remove last closing brackets
awk '{lines[NR]=$0} /^}$/ {last=NR} END {for(i=1;i<last;i++) print lines[i]}' /etc/nginx/nginx.conf > tmp && mv tmp /etc/nginx/nginx.conf

# add new configuration and add last closing brackets
cat <<EOF >> /etc/nginx/nginx.conf
    server {
        listen 8000 default_server;
        listen [::]:8000 default_server;
        location = /basic_status {
            stub_status;
        }
        root /var/www/html;
        index index.html index.nginx-debian.html
        server_name _;
        location / {
          try_files \$uri \$uri/ =404;
        }
    }
}
EOF

service nginx restart
