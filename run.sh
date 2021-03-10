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
mysql -Bse "CREATE DATABASE $DBNAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
mysql -Bse "GRANT ALL ON $DBNAME.* TO '$DBUSER'@'localhost' IDENTIFIED BY '$DBPW';"
mysql -Bse "FLUSH PRIVILEGES;"

# Install the WP-CLI Tool
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp-cli
mkdir /var/www/wordpress
cd /var/www/wordpress
wp-cli core download --allow-root
wp-cli config create --dbname=$DBNAME --dbuser=$DBUSER --dbpass=$DBPW --locale=en_DB --allow-root
wp-cli core install --url=$DOMAIN --title=$DOMAIN --admin_user=$DBUSER --admin_password=$DBPW --email=email@gmail.com --allow-root
sudo chown -R www-data:www-data /var/www/wordpress
