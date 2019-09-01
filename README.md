# finalize_ubuntu
Simpel bash script to run after fresh ubuntu installation

=====================================
**Finish Ubuntu 18.04 base installation**
=====================================

This script will:
  * Download and install latest currently installed packages
  * Download and install latest kernel
  * Download and install NTP daemon (connecting to dutch based NTP servers)
  * Download and install some generic development packages
  * Configure IP tables to only open ports 22,80 and 443

Optionally:
  * Download and install MariaDB
  * Download and install NGINX
  * Download and install PHP7.3 (including composer)
  * Download and install Redis (server)

This script has been tested on Ubuntu 18.04  Running it on other environments may not work correctly.

WARNING 1: This script should be run as root

WARNING 2: Please review the original source code at https://github.com/moroswitie/finalize_ubuntu/finish-install.sh if you have any concerns

WARNING 3: You run this script entirely at your own risk.

Usage:
wget -N https://github.com/moroswitie/finalize_ubuntu/raw/master/finish-install.sh&&bash finish-install.sh

