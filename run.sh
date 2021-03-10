#!/bin/bash

if [ $EUID -ne 0 ]; then
    echo "$0 is not running as root. Try using sudo."
    exit 2
fi

DOMAIN=google.com

# mysql & wordpress variables
DBNAME='google'
DBUSER='wordpressuser'
DBPW='password'

# easy-rsa variables
SERVER='google-nginx'
CLIENT='client1'

IP=$(hostname  -I | cut -f1 -d' ')
RIP=$(echo $IP | awk -F. '{print $4"."$3"."$2"."$1}') # Reverse IP for PTR record

ufw disable # is disable by default. Here I just make sure
apt update

yes | apt install nginx
yes | apt install php-fpm php-mysql php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip
systemctl restart php7.2-fpm

yes | apt install mysql-server
