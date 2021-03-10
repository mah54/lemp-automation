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

#Install latest version of EasyRSA
wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz -P ~
tar xzvf EasyRSA-3.0.8.tgz
mv ~/EasyRSA-3.0.8 ~/easy-rsa
rm ~/EasyRSA-3.0.8.tgz
echo yes | ~/easyrsa init-pki 2> /dev/null
mv ~/lemp-automation/vars ~/easy-rsa
echo | ~/easyrsa build-ca nopass 2> /dev/null
~/easyrsa build-server-full $SERVER nopass
~/easyrsa build-client-full $CLIENT nopass
mkdir /etc/nginx/ssl
cp ~/easy-rsa/pki/private/$SERVER.key /etc/nginx/ssl/
cp ~/easy-rsa/pki/issued/$SERVER.crt /etc/nginx/ssl/
cp ~/easy-rsa/pki/ca.crt /etc/nginx/ssl/
cp ~/easy-rsa/pki/ca.crt ~/
cp ~/easy-rsa/pki/issued/$CLIENT.crt ~/$CLIENT.pem
cat ~/easy-rsa/pki/private/$CLIENT.key >> ~/$CLIENT.pem

# nginx configuration file
mv ~/lemp-automation/DOMAIN ~/lemp-automation/$DOMAIN
sed -i s/IP/$IP/g ~/lemp-automation/$DOMAIN
sed -i  s/WSERVER/$SERVER/g  ~/lemp-automation/$DOMAIN
sed -i  s/DOMAIN/$DOMAIN/g  ~/lemp-automation/$DOMAIN
mv ~/lemp-automation/$DOMAIN /etc/nginx/sites-available/
ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
unlink /etc/nginx/sites-enabled/default

nginx -s reload

# install bind9
yes | apt install bind9 bind9utils bind9-doc dnsutils
mkdir /etc/bind/zones
