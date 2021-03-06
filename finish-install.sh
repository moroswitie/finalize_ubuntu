#!/bin/bash
# Copyright (C) 2020 Moroswitie

echo "
#########################################################################
#               Finish Ubuntu 20.04 LTS base installation               #
#########################################################################

This script will:
  * Download and install latest currently installed packages
  * Download and install latest kernel
  * Download and install NTP daemon (connecting to dutch based NTP servers)
  * Download and install some generic development packages
  * Configure IP tables to only open ports 22,80 and 443

This script has been tested on Ubuntu 20.04  Running it on other environments may not work correctly.

WARNING 1: This script should be run as root
WARNING 2: Please review the original source code at https://github.com/moroswitie/finalize_ubuntu/finish-install.sh if you have any concerns
WARNING 3: You run this script entirely at your own risk.
"

# Login as root user and execute below commands or append sudo to all commands

read -r -p "Do you want to run this script? [y/N] " response
response=${response,,}    #
if [[ $response =~ ^(yes|y)$ ]]; then
    echo "Starting script";
else
    echo "Terminating script";
    exit;
fi

echo "Downloading and installing latest currently installed packages";
echo "===============================================================";
echo
apt update && apt dist-upgrade -y && apt autoremove && apt autoclean

echo
echo "Downloading and installing some basic tools";
echo "===============================================================";
echo

# disable iptables prompt
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

# install base packages
apt install -y --allow-unauthenticated build-essential checkinstall ntp ntpdate software-properties-common \
bzip2 zip iptables-persistent git bash-completion vim curl htop dirmngr apt-transport-https gnupg2 \
ca-certificates lsb-release
apt purge -y --allow-remove-essential --auto-remove snapd

echo
echo "Adding some aliases";
echo "===============================================================";
echo

echo "alias lsa='ls -lah --color=always'" > /etc/profile.d/00-aliases_finalize_script.sh
echo "alias ls='ls --color=always'" >> /etc/profile.d/00-aliases_finalize_script.sh

echo
echo "Configuring iptables: opening ports 22,80,443";
echo "===============================================================";

iptables -I INPUT 1 -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
iptables -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p udp --dport 33434:33534 -j REJECT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -j DROP
iptables-save > /etc/iptables/rules.v4

echo "done";
echo
echo "Configuring NTP servers";
echo "===============================================================";

# /etc/ntp.conf, configuration for ntpd; see ntp.conf(5) for help
# Create NTP config
echo "# /etc/ntp.conf, configuration for ntpd;" > /etc/ntp.conf
echo "driftfile /var/lib/ntp/ntp.drift" >> /etc/ntp.conf
echo "" >> /etc/ntp.conf
echo "# Specify one or more NTP servers." >> /etc/ntp.conf
echo "server 0.nl.pool.ntp.org" >> /etc/ntp.conf
echo "server 1.nl.pool.ntp.org" >> /etc/ntp.conf
echo "server 2.nl.pool.ntp.org" >> /etc/ntp.conf
echo "server 3.nl.pool.ntp.org" >> /etc/ntp.conf
echo "# Use Ubuntu's ntp server as a fallback." >> /etc/ntp.conf
echo "server 0.europe.pool.ntp.org" >> /etc/ntp.conf
echo "" >> /etc/ntp.conf
echo "# By default, exchange time with everybody, but don't allow configuration." >> /etc/ntp.conf
echo "restrict -4 default kod notrap nomodify nopeer noquery" >> /etc/ntp.conf
echo "restrict -6 default kod notrap nomodify nopeer noquery" >> /etc/ntp.conf
echo "" >> /etc/ntp.conf
echo "# Local users may interrogate the ntp server more closely." >> /etc/ntp.conf
echo "restrict 127.0.0.1" >> /etc/ntp.conf
echo "restrict ::1" >> /etc/ntp.conf
service ntp restart
echo "done";
echo

echo "
#####################################################################
#                Part 2 -  NGINX, PHP and MariaDB                  #
#####################################################################

We can also install NGINX, PHP8 and MariaDB:
  * Download and install NGINX (from NGINX not from ubuntu repo)
  * Download and install PHP8
  * Download and install MariaDB
  * Configure NGINX to support PHP (Experimental)
"

read -r -p "Do you want to install part 2 [y/N] " response
response=${response,,}    #
if [[ $response =~ ^(yes|y)$ ]]; then
    echo "Starting part 2.... SORRY this part is still underdevelopment";

    # MariaDB
    apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
    touch /etc/apt/sources.list.d/MariaDB.list
    echo "deb [arch=amd64,arm64,ppc64el] https://mariadb.mirror.pcextreme.nl/repo/10.5/ubuntu focal main" > /etc/apt/sources.list.d/MariaDB.list
    echo "deb-src https://mariadb.mirror.pcextreme.nl/repo/10.5/ubuntu focal main" >> /etc/apt/sources.list.d/MariaDB.list

    # Nginx
    wget http://nginx.org/keys/nginx_signing.key
    apt-key add nginx_signing.key
    rm -f ./nginx_signing.key
    touch /etc/apt/sources.list.d/nginx.list
    echo "deb http://nginx.org/packages/mainline/ubuntu/ focal nginx" > /etc/apt/sources.list.d/nginx.list
    echo "deb-src http://nginx.org/packages/mainline/ubuntu/ focal nginx" >> /etc/apt/sources.list.d/nginx.list

    # PPA Redis
    add-apt-repository ppa:chris-lea/redis-server -y
    
    # PHP 8.* (PHP 7.* available if needed)
    add-apt-repository ppa:ondrej/php -y

    apt update
else
    echo "Terminating script";
    exit;
fi

read -r -p "Do you want to install MariaDB [y/N] " response
response=${response,,}    #
if [[ $response =~ ^(yes|y)$ ]]; then
    echo "Installing MariaDB";
    echo "====================";
    apt install -y --allow-unauthenticated mariadb-server
    echo "done"
    echo
fi

read -r -p "Do you want to install PHP 8.0 (including composer) [y/N]" response
response=${response,,}    #
if [[ $response =~ ^(yes|y)$ ]]; then
    echo "Installing PHP 8.0";
    echo "====================";
    apt install -y --allow-unauthenticated php8.0-fpm php8.0-mysql php8.0-redis php8.0-curl php8.0-zip php8.0-igbinary \
    php8.0-mbstring php8.0-soap php8.0-xml php8.0-xsl php8.0-bcmath php8.0-gd php8.0-imap php8.0-imagick php8.0-uuid \
    php8.0-yaml
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    echo "done"
    echo
fi

read -r -p "Do you want to install nginx [y/N] " response
response=${response,,}    #
if [[ $response =~ ^(yes|y)$ ]]; then
    echo "Installing nginx";
    echo "====================";
    apt install -y nginx
    echo "done"
    echo
fi

read -r -p "Do you want to install Redis [y/N]" response
response=${response,,}    #
if [[ $response =~ ^(yes|y)$ ]]; then
    echo "Installing Redis";
    echo "====================";
    apt install -y redis-server
    echo "done"
    echo
fi

read -r -p "Do you want to try and configure nginx and php [y/N]" response
response=${response,,}    #
if [[ $response =~ ^(yes|y)$ ]]; then
    echo "Changing PHP fpm to listen on a TCP socket ";
    # Comment out current listen setting, and add a new one below it
    sed -i -e 's@listen = /run/php/php8.0-fpm.sock@; listen = /run/php/php8.0-fpm.sock\nlisten = 127.0.0.1:9000@g' /etc/php/8.0/fpm/pool.d/www.conf
    echo "done"
    echo

    echo "Setting up NGINX"
    echo "====================";
    DIR_ENABLED=/etc/nginx/sites-enabled/
    DIR_AVAILABLE=/etc/nginx/sites-available/
    DIR_SNIPPETS=/etc/nginx/snippets/
    DIR_WWW=/var/www/html/
    [ -d "$DIR_ENABLED" ] || mkdir ${DIR_ENABLED}
    [ -d "$DIR_AVAILABLE" ] || mkdir ${DIR_AVAILABLE}
    [ -d "$DIR_SNIPPETS" ] || mkdir ${DIR_SNIPPETS}
    [ -d "$DIR_WWW" ] || mkdir -p ${DIR_WWW}

    # download default nginx configs and put in correct locations, adjust some php.ini defaults
    wget https://github.com/moroswitie/finalize_ubuntu/raw/master/nginx/nginx.conf
    wget https://github.com/moroswitie/finalize_ubuntu/raw/master/nginx/fastcgi.conf
    wget https://github.com/moroswitie/finalize_ubuntu/raw/master/nginx/snippets/fastcgi-php.conf
    wget https://github.com/moroswitie/finalize_ubuntu/raw/master/nginx/snippets/well-known.conf
    wget https://github.com/moroswitie/finalize_ubuntu/raw/master/nginx/sites-available/default
    wget https://github.com/moroswitie/finalize_ubuntu/raw/master/php/php.ini
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
    mv ./nginx.conf /etc/nginx/
    mv ./fastcgi.conf /etc/nginx/
    mv ./fastcgi-php.conf /etc/nginx/snippets/
    mv ./well-known.conf /etc/nginx/snippets/
    mv ./default /etc/nginx/sites-available/
    mv /etc/php/8.0/fpm/php.ini /etc/php/8.0/fpm/php.ini.backup
    mv ./php.ini /etc/php/8.0/fpm/php.ini

    # keep same user as default from distro
    # sed -i -e 's/user www-data/user nginx/g' /etc/nginx/nginx.conf

    # Fix log rotate
    sed -i -e 's/nginx adm/www-data adm/g' /etc/logrotate.d/nginx

    # create symlink to file if it doesn't exist
    DEFAULT_SITE=/etc/nginx/sites-enabled/default
    if ! [ -L "$DEFAULT_SITE" ]; then
        # does not exist create symlink
        ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    fi

    # Delete old default file
    DEFAULT_CONFIG=/etc/nginx/conf.d/default.conf
    if [ -f "$DEFAULT_CONFIG" ]; then
        rm "$DEFAULT_CONFIG" -f
    fi

    # Create info page
    echo "<?php" > /var/www/html/info.php
    echo "phpinfo();" >> /var/www/html/info.php
    service php8.0-fpm restart
    service nginx restart
    echo "done"

fi
