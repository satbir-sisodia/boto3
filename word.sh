#!/bin/bash
# Script use to install LEMP stack on Debian 
#--------------------------------------------------
# Software version:
# 1. OS: 10.3 (Buster) 64 bit
# 2. Nginx: 1.14.2
# 3. MariaDB: 10.3
# 4. PHP 7: 7.3.3-1+0~20190307202245.32+stretch~1.gbp32ebb2
#--------------------------------------------------
# List function:
# 1. checkroot: check to make sure script can be run by user root
# 2. update: update all the packages
# 3. install: funtion to install LEMP stack
# 4. init: function use to call the main part of installation
# 5. main: the main function, add your functions to this place

# Function check user root
checkroot() {
    if (($EUID == 0)); then
        # If user is root, continue to function init
        init
    else
        # If user not is root, print message and exit script
        echo "Please run this script by user root ."
        exit
    fi
}

# Function update os
update() {
    echo "Initiating Update and Upgrade..."
    echo ""
    sleep 1
        apt update
        apt upgrade -y
    echo ""
    sleep 1
}

# Function install LEMP stack
install() {

    ########## INSTALL NGINX ##########
    echo ""
    echo "Installing NGINX..."
    echo ""
    sleep 1
        apt install nginx -y
        systemctl enable nginx && systemctl restart nginx
    echo ""
    sleep 1

    ########## INSTALL MYSQL ##########
    echo "Installing MYSQL-SERVER..."
    echo ""
    sleep 1
        apt install mysql-server -y
        systemctl enable mysql && systemctl restart mysql
    echo ""
    sleep 1

    echo "CREATING DB and USER ..."
    echo ""
        mysql -uroot -proot -e "ALTER USER 'root'@'localhoat' IDENTIFIED BY 'password'; "
        mysql -uroot -proot -e "CREATE DATABASE wordpress_db /*\!40100 DEFAULT CHARACTER SET utf8 */;"
        mysql -uroot -proot -e "CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'password';"
        mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wpuser'@'localhost';"
        mysql -uroot -proot -e "FLUSH PRIVILEGES;"
    echo ""
    sleep 1

    ########## INSTALL PHP7 ##########
    # This is unofficial repository, it's up to you if you want to use it.
    echo "Installing PHP 7.3..."
    echo ""
    sleep 1
        sudo apt-add-repository ppa:ondrej/php -y
        sudo apt update
        apt install php7.3 php7.3-cli php7.3-common php7.3-fpm php7.3-gd php7.3-mysql -y
    echo ""
    sleep 1

    ########## MODIFY GLOBAL CONFIGS ##########
    echo "Modifying Global Configurations..."
    echo ""
    sleep 1
        sed -i 's:# Basic Settings:client_max_body_size 24m;:g' /etc/nginx/nginx.conf
        sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 12M/g' /etc/php/7.3/fpm/php.ini
        sed -i 's/post_max_size = 2M/post_max_size = 12M/g' /etc/php/7.3/fpm/php.ini
    echo ""
    sleep 1

    ########## PREPARE DIRECTORIES ##########
    echo "Preparing WordPress directory..."
    echo ""
    sleep 1
        mkdir /var/www/wordpress
        echo "<?php phpinfo(); ?>" >/var/www/wordpress/info.php
        chown -R www-data:www-data /var/www/wordpress
    echo ""
    sleep 1

    ########## MODIFY VHOST CONFIG ##########
    echo "Modifying Default VHost for Nginx..."
    echo ""
    sleep 1
cat >/etc/nginx/sites-enabled/default <<"EOF"
server {
        listen 80 ;
        listen [::]:80 ;
        root /var/www/wordpress;
        index index.php index.html index.htm index.nginx-debian.html;
        #server_name_;
             location / {
                 try_files $uri $uri/ /index.php$is_args$args;
        }

        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        
        }
}


EOF
    echo ""
    sleep 1

    ########## RESTARTING NGINX AND PHP ##########
    echo "Restarting Nginx & PHP..."
    echo ""
    sleep 1
        systemctl restart nginx
        systemctl restart php7.3-fpm
    echo ""
    sleep 1

    ########## INSTALLING WORDPRESS ##########
    echo "Installing WordPress..."
    echo ""
        wget -c http://wordpress.org/latest.tar.gz
        tar -xzvf latest.tar.gz
        rsync -av wordpress/* /var/www/wordpress/
        chown -R www-data:www-data /var/www/wordpress/
        chmod -R 755 /var/www/wordpress/
        curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        chmod +x wp-cli.phar
        mv wp-cli.phar /usr/local/bin/wp
        wp --info
    echo ""
    sleep 1

    ########## ENDING MESSAGE ##########
    sleep 1
    echo ""
        # local start="You can access http://"
        # local mid=`ip a | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`
        # local end="/ to setup your WordPress."
        # echo "$start$mid$end"
        echo "MySQL db: wordpress user: wordpress pwd: wordpress "
        echo "Thank you for using our script, Decrypt-Block! ..."
    echo ""
    sleep 1

}

# initialized the whole installation.
init() {
    update
    install
}

# primary function check.
main() {
    checkroot
}
main
exit