#!/usr/bin/env bash

set -e

DOMAIN=$1

# Wait for cloud-init to complete
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

# Prevent apt-daily from holding up /var/lib/dpkg/lock on boot
systemctl stop apt-daily.timer
systemctl stop apt-daily.service

# Make swap
dd if=/dev/zero of=/swapfile bs=1M count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap defaults 0 0' >> /etc/fstab

# Install Digital Ocean new metrics
curl -sSL https://agent.digitalocean.com/install.sh | sh

# Install programs
apt-get update
DEBIAN_FRONTEND='noninteractive' apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade -y
DEBIAN_FRONTEND='noninteractive' apt-get install -y \
  ntp nginx jq curl iptables-persistent build-essential python2.7-dev libffi-dev \
  python-pip python-setuptools sqlite3 libssl-dev python-virtualenv \
  libjpeg-dev libxslt1-dev postgresql postgresql-contrib git-core

# Remove unscd as it causes issues with chpasswd
apt-get remove -y unscd

