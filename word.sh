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
    echo "Enter wordpress database name!"
	read dbname
    
	echo "Creating new WordPress database..."
	mysql -e "CREATE DATABASE ${dbname} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	echo "Database successfully created!"
	
	echo "Enter wordpress database user!"
	read username
    
	echo "Enter the PASSWORD for wordpress database user!"
	echo "Note: password will be hidden when typing"
	read -s userpass
    
	echo "Creating new user..."
	mysql -e "CREATE USER ${username}@localhost IDENTIFIED BY '${userpass}';"
	echo "User successfully created!"

	echo "Granting ALL privileges on ${dbname} to ${username}!"
	mysql -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${username}'@'localhost';"
	mysql -e "FLUSH PRIVILEGES;"
	echo "You're good now :)"
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
    listen 80;
    listen [::]:80;
    root /var/www/wordpress;
    index index.php index.html index.htm;
    server_name _;
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    location ~ ^/wp-json/ {
        # if permalinks not enabled
        rewrite ^/wp-json/(.*?)$ /?rest_route=/$1 last;
    }
    location ~ \.php$ {
        include         fastcgi_params;
        fastcgi_pass    unix:/run/php/php7.3-fpm.sock;
        fastcgi_param   SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_index   index.php;
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
