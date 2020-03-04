#!/usr/bin/env bash

set -e

DOMAIN_NAME=$1

# Add Yggdrasil repo
wget -O - https://neilalexander.s3.eu-west-2.amazonaws.com/deb/key.txt | apt-key add -
echo 'deb http://neilalexander.s3.eu-west-2.amazonaws.com/deb/ debian yggdrasil' | tee /etc/apt/sources.list.d/yggdrasil.list
apt-get update
DEBIAN_FRONTEND='noninteractive' apt-get install -y yggdrasil
systemctl enable yggdrasil
sed -i -e "s/NodeInfo: {}/NodeInfo: { \"name\": \"y.matrix.$DOMAIN\" }/g" /etc/yggdrasil.conf
sed -i -e "s/IfName: auto/IfName: ygg0/g" /etc/yggdrasil.conf
systemctl start yggdrasil

# Get cjdns IPv6
sleep 15
yggdrasilctl getSelf | grep "IPv6 address" | awk -F " " '{ print $3 }'| tr -d '\n'  > /tmp/matrix-server/ipv6-yggdrasil

# Add h.matrix and h.chat to Dehydrated
CONTENT=$(cat /opt/dehydrated/domains.txt)

echo -n "$CONTENT y.chat.$DOMAIN_NAME y.matrix.$DOMAIN_NAME" > /opt/dehydrated/domains.txt
