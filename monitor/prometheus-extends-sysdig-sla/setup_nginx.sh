#!/bin/bash

# copy the current nginx config (it will be used later)
cp /etc/nginx/nginx.conf /root/nginx.conf

# remove last closing brackets
sed -i '$ d' /etc/nginx/nginx.conf

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
