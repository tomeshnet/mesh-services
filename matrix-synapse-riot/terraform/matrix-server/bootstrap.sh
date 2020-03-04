#!/usr/bin/env bash

set -e

DOMAIN=$1
DNS=$2

# Wait for cloud-init to complete
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

# Prevent apt-daily from holding up /var/lib/dpkg/lock on boot
systemctl stop apt-daily.timer
systemctl stop apt-daily.service

# Set DNS server
if [ $DNS ]
then
	echo "nameserver $DNS" > /etc/resolv.conf
	chattr +i /etc/resolv.conf
fi

# Make swap
dd if=/dev/zero of=/swapfile bs=1M count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap defaults 0 0' >> /etc/fstab

# Remove unscd as it causes issues with chpasswd
DEBIAN_FRONTEND='noninteractive' apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" remove -y unscd

# Install programs
apt-get update
DEBIAN_FRONTEND='noninteractive' apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade -y
DEBIAN_FRONTEND='noninteractive' apt-get install -y ntp nginx jq curl iptables-persistent build-essential libssl-dev libxslt1-dev postgresql postgresql-contrib git-core apt-transport-https
