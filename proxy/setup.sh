#!/usr/bin/env bash

log=/error.log

if [ -z "${nginx_server_name}" ]; then
  export nginx_server_name="localhost"
fi

if [ -z "${nginx_ssl}" ]; then
  export nginx_ssl="0"
elif [ "${nginx_ssl}" -eq "1" ]; then
  if [ -z "${nginx_ssl_root}" ]; then
    echo "ERROR: `nginx_ssl_root` must exist if `nginx_ssl` -eq 1 "
    exit 1
  elif [ ! -f "${nginx_ssl_root}/cert.key" ]; then
    echo "ERROR: `${nginx_ssl_root}/cert.key` must exist"
    exit 1
  elif [ ! -f "${nginx_ssl_root}/cert.crt" ]; then
    echo "ERROR: `${nginx_ssl_root}/cert.crt` must exist"
    exit 1
  fi
fi

if [ -z "${nginx_gzip}" ]; then
  export nginx_gzip="1"
fi

setup() {

# Setup base config
cat << EOF | tee -a /etc/nginx/nginx.conf >> $log
user  nginx;
worker_processes  1;

events {
  worker_connections  1024;
}

http {
  include       /etc/nginx/mime.types;
  default_type  application/octet-stream;

  access_log $log;
  error_log $log;

EOF

if [ "${nginx_gzip}" -ne "0" ]; then

cat << EOF | tee -a /etc/nginx/nginx.conf >> $log

  gzip              on;
  gzip_http_version 1.0;
  gzip_proxied      any;
  gzip_min_length   500;
  gzip_disable      "MSIE [1-6]\.";
  gzip_types        text/plain text/xml text/css
                    text/comma-separated-values
                    text/javascript
                    application/x-javascript
                    application/atom+xml;

EOF

fi

if [ "${nginx_ssl}" -eq "1" ]; then

cat << EOF | tee -a /etc/nginx/nginx.conf >> $log
  server {
    listen          80;
    server_name     ${nginx_server_name};
    rewrite ^/(.*)  https://\$host/\$1 permanent;
  }

  server {
    listen          443;
    server_name     ${nginx_server_name};

    ssl on;
    ssl_certificate ${nginx_ssl_root}/cert.crt;
    ssl_certificate_key ${nginx_ssl_root}/cert.key;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';

EOF

else

cat << EOF | tee -a /etc/nginx/nginx.conf >> $log
  server {
    listen          80;
    server_name     ${nginx_server_name};

EOF

fi

cat << EOF | tee -a /etc/nginx/nginx.conf >> $log
    charset utf-8;
    client_max_body_size 20M;
    sendfile on;
    keepalive_timeout  65;
    large_client_header_buffers 8 32k;

EOF

# Setup proxy configs
env | grep "^nginx_proxy_" | while IFS="=" read key val; do

IFS=" " read path pass <<< "${val}"

cat << EOF | tee -a /etc/nginx/nginx.conf >> $log
    location ${path} {
      proxy_pass         ${pass};
      proxy_set_header   Host \$host;
      proxy_set_header   X-Real-IP \$remote_addr;
      proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header   X-Forwarded-Host \$server_name;
    }
EOF

done

# Setup redirect configs
env | grep "^nginx_redirect_" | while IFS="=" read key val; do

IFS=" " read path pass <<< "${val}"

cat << EOF | tee -a /etc/nginx/nginx.conf >> $log
    location ~ ^${path} {
      rewrite ^${path}(.*)$ ${pass}\$1 redirect;
    }          
EOF

done

# Finish config
cat << EOF | tee -a /etc/nginx/nginx.conf >> $log
  }
}
EOF

}


if [ -f $log ]; then
  rm $log
fi

touch $log
tail -f $log &
setup && exec "$@"
