#!/bin/bash
# Copyright (C) 2016 Moroswitie

echo "
#####################################################################
#               Finish Ubuntu 16.04 base installation               #
#####################################################################

This script will:
  * Download and install latest currently installed packages
  * Download and install latest kernel
  * Download and install NTP daemon (connecting to dutch based NTP servers)
  * Download and install some generic development packages

This script has been tested on Ubuntu 16.04  Running it on other environments may not work correctly.

WARNING 1: This script should be run as root
WARNING 2: Please review the original source code at https://github.com/moroswitie/finalize_ubuntu/finish-install.sh if you have any concerns
WARNING 2: You run this script entirely at your own risk.
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
apt-get update && apt-get dist-upgrade -y && apt-get autoremove && apt-get autoclean

echo
echo "Downloading and installing some basic tools";
echo "===============================================================";
echo

apt-get install -y build-essential checkinstall ntp ntpdate software-properties-common bzip2 zip sysv-rc-conf iptables-persistent git bash-completion


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
echo "server ntp.ubuntu.org" >> /etc/ntp.conf
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

We can also install NGINX, PHP7 and MariaDB:
  * Download and install NGINX (from NGINX not from ubuntu repo)
  * Download and install PHP7
  * Download and install MariaDB
  * Configure NGINX to support PHP (Experimental)
"

read -r -p "Do you want to install part 2 [y/N] " response
response=${response,,}    #
if [[ $response =~ ^(yes|y)$ ]]; then
    echo "Starting part 2.... SORRY this part is still underdevelopment";

    apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
    add-apt-repository 'deb [arch=amd64,i386] http://mirror.i3d.net/pub/mariadb/repo/10.1/ubuntu xenial main'

    wget http://nginx.org/keys/nginx_signing.key
    apt-key add nginx_signing.key
    rm -f ./nginx_signing.key
    touch /etc/apt/sources.list.d/nginx.list
    echo "deb http://nginx.org/packages/mainline/ubuntu/ xenial nginx" > /etc/apt/sources.list.d/nginx.list
    echo "deb-src http://nginx.org/packages/mainline/ubuntu/ xenial nginx" >> /etc/apt/sources.list.d/nginx.list
    apt-get update
else
    echo "Terminating script";
    exit;
fi

read -r -p "Do you want to install MariaDB [y/N] " response
response=${response,,}    #
if [[ $response =~ ^(yes|y)$ ]]; then
    echo "Installing MariaDB";
    echo "====================";
    apt-get install -y mariadb-server
    echo "done"
    echo
fi

read -r -p "Do you want to install nginx [y/N] " response
response=${response,,}    #
if [[ $response =~ ^(yes|y)$ ]]; then
    echo "Installing nginx";
    echo "====================";
    apt-get install -y nginx
    echo "done"
    echo
fi


read -r -p "Do you want to install PHP 7.0 [y/N] " response
response=${response,,}    #
if [[ $response =~ ^(yes|y)$ ]]; then
    echo "Installing PHP 7.0";
    echo "====================";
    apt-get install -y php7.0-fpm php7.0-mysql php-redis php7.0-curl php7.0-mcrypt php7.0-zip
    echo "done"
    echo
fi