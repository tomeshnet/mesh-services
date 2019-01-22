#!/usr/bin/env bash

set -e

CJDNS_VERSION=20.2

DOMAIN_NAME=$1

# Download cjdns
cd /opt/
wget https://github.com/cjdelisle/cjdns/archive/cjdns-v$CJDNS_VERSION.tar.gz 
tar xf cjdns-v$CJDNS_VERSION.tar.gz
ln -s cjdns-cjdns-v$CJDNS_VERSION cjdns

# Install NODE
curl -sL https://deb.nodesource.com/setup_10.x | bash -
apt-get install -y nodejs

# Install cjdns
cd cjdns
./do
cp cjdroute /usr/bin/cjdroute
cjdroute --genconf | sudo tee --append /etc/cjdroute.conf > /dev/null

# Set up cjdns systemd service
cp contrib/systemd/cjdns.service /etc/systemd/system/cjdns.service
chmod 644 /etc/systemd/system/cjdns.service
cp contrib/systemd/cjdns-resume.service /etc/systemd/system/cjdns-resume.service
chmod 644 /etc/systemd/system/cjdns-resume.service
systemctl daemon-reload
systemctl enable cjdns.service
systemctl start cjdns.service

# Get cjdns IPv6
cat /etc/cjdroute.conf | grep "\"ipv6\"" | awk -F '"' '{ print $4 }' | tr -d '\n' > /tmp/matrix-server/ipv6-cjdns

# Add h.matrix and h.chat to Dehydrated
CONTENT=$(cat /opt/dehydrated/domains.txt)

echo -n "$CONTENT h.chat.$DOMAIN_NAME h.matrix.$DOMAIN_NAME" > /opt/dehydrated/domains.txt

