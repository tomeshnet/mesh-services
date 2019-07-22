#!/usr/bin/env bash

set -e

RIOT_VERSION=1.3.0

DOMAIN_NAME=$1
DO_TOKEN=$2

DEHYDRATED_VERSION=0.6.5

#######################
# nginx + letsencrypt #
#######################
systemctl stop nginx.service

# Generate dhparam.pem
echo "Generating DH parameters, 4096 bit long safe prime, generator 2"
echo "This is going to take a long time"
openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096 2> /dev/null

# Copy nginx config to directory 
systemctl restart nginx.service
cd /etc/nginx/
mkdir -m 700 ssl
cp /tmp/matrix-server/nginx-chat /etc/nginx/sites-available/chat.$DOMAIN_NAME
sed -i -e "s/__DOMAIN_NAME__/$DOMAIN_NAME/g" /etc/nginx/sites-available/chat.$DOMAIN_NAME
cp /tmp/matrix-server/nginx-matrix /etc/nginx/sites-available/matrix.$DOMAIN_NAME
sed -i -e "s/__DOMAIN_NAME__/$DOMAIN_NAME/g" /etc/nginx/sites-available/matrix.$DOMAIN_NAME
ln -s /etc/nginx/sites-available/matrix.$DOMAIN_NAME /etc/nginx/sites-enabled/matrix.$DOMAIN_NAME
ln -s /etc/nginx/sites-available/chat.$DOMAIN_NAME /etc/nginx/sites-enabled/chat.$DOMAIN_NAME

# Install Dehydrated 
cd /opt/
wget https://github.com/lukas2511/dehydrated/releases/download/v$DEHYDRATED_VERSION/dehydrated-$DEHYDRATED_VERSION.tar.gz -O /opt/dehydrated-$DEHYDRATED_VERSION.tar.gz
tar xf dehydrated-$DEHYDRATED_VERSION.tar.gz
rm dehydrated-$DEHYDRATED_VERSION.tar.gz
chmod 700 /opt/dehydrated-$DEHYDRATED_VERSION
cd /opt/dehydrated-$DEHYDRATED_VERSION
cp /tmp/matrix-server/dehydrated-config /opt/dehydrated-$DEHYDRATED_VERSION/config
cp /tmp/matrix-server/dehydrated-hooks /opt/dehydrated-$DEHYDRATED_VERSION/hooks.sh
echo -n "chat.$DOMAIN_NAME matrix.$DOMAIN_NAME $DOMAIN_NAME" > /opt/dehydrated-$DEHYDRATED_VERSION/domains.txt
chmod +x /tmp/matrix-server/dehydrated-hooks /opt/dehydrated-$DEHYDRATED_VERSION/hooks.sh
ln -s /opt/dehydrated-$DEHYDRATED_VERSION /opt/dehydrated
cd /opt/dehydrated
sed -i -e "s/__DO_TOKEN__/$DO_TOKEN/g" hooks.sh

# Register to Let's Encrypt
./dehydrated --register --accept-terms

cp /tmp/matrix-server/bootstrap-dehydrated.sh /usr/local/sbin/dehydrated-renew.sh

# Configure auto-renewals
sh -c '(crontab -l 2>/dev/null; echo "@weekly /usr/local/sbin/dehydrated-renew.sh") | crontab -'

############
# iptables #
############
cp /tmp/matrix-server/ip6tables-rules /etc/iptables/rules.v6
cp /tmp/matrix-server/iptables-rules /etc/iptables/rules.v4
ip6tables-restore /etc/iptables/rules.v6
iptables-restore /etc/iptables/rules.v4

#######################
# Make non-root users #
#######################
set +e
sysadminuser=$(grep -c '^sysadmin:' /etc/passwd)
set -e
if [ $sysadminuser -eq 0 ]
then
	useradd -s /bin/bash -N -g users -G sudo -m sysadmin
	cp -r /root/.ssh /home/sysadmin/
	chown -R sysadmin:users /home/sysadmin/.ssh
fi
passwd=$(dd if=/dev/urandom bs=1M count=500 | sha256sum | awk '{ print $1 }')
echo "sysadmin:$passwd" | /usr/sbin/chpasswd
echo -n $passwd > /tmp/matrix-server/passwd-sysadmin

########
# PSQL #
########
cd /
# Generate an password for synapse database
DATAPASS=$(dd if=/dev/urandom bs=1M count=500 | sha256sum | awk '{ print $1 }')
su -c "/tmp/matrix-server/psql-setup.sh $DATAPASS" postgres

###########
# Synapse #
###########
echo "deb https://matrix.org/packages/debian stretch main" > /etc/apt/sources.list.d/synapse.list 
echo "deb-src https://matrix.org/packages/debian stretch main" >> /etc/apt/sources.list.d/synapse.list 
wget -qO - https://matrix.org/packages/debian/repo-key.asc | sudo apt-key add -
apt-get update
DEBIAN_FRONTEND='noninteractive' apt-get install -y matrix-synapse-py3
systemctl enable matrix-synapse
systemctl stop matrix-synapse
cd /etc/matrix-synapse/

# Generate config file
echo "server_name: $DOMAIN_NAME" > conf.d/server_name.yaml
sed -i -e "s/x_forwarded: false/x_forwarded: true/g" homeserver.yaml
echo "
url_preview_ip_range_blacklist:
 - '127.0.0.0/8'
 - '10.0.0.0/8'
 - '172.16.0.0/12'
 - '192.168.0.0/16'
 - '100.64.0.0/10'
 - '169.254.0.0/16'
 - '::1/128'
 - 'fe80::/64'">> homeserver.yaml
sed -i '/## Database ##/,/^$/d' homeserver.yaml
sed -i '/database:/,/^$/d' homeserver.yaml
echo "enable_group_creation: true" >> conf.d/custom.yaml
echo "enable_registration: true" >> conf.d/custom.yaml
echo "allow_guest_access: true" >> conf.d/custom.yaml
echo "url_preview_enabled: true" >> conf.d/custom.yaml
echo "cleanup_extremities_with_dummy_events: true" >> conf.d/custom.yaml
echo "
# Database configuration
# Postgres database configuration
database:
    name: psycopg2
    args:
        user: synapse_user
        password: $DATAPASS
        database: synapse
        host: localhost
        cp_min: 5
        cp_max: 10
" >> homeserver.yaml
echo "synctl_cache_factor: 0.02" >> homeserver.yaml
awk '1;/listeners:/{ print "  - port: 8448\n    type: http\n    tls: true\n    resources:\n      - names: [client, federation]"}' homeserver.yaml > homeserver.yaml.new
mv homeserver.yaml.new homeserver.yaml

echo "tls_certificate_path: \"/etc/matrix-synapse/homeserver.tls.crt\"" > conf.d/ssl.yaml
echo "tls_private_key_path: \"/etc/matrix-synapse/homeserver.tls.key\"" >> conf.d/ssl.yaml

########
# Riot #
########
cd /var/www/
wget https://github.com/vector-im/riot-web/releases/download/v$RIOT_VERSION/riot-v$RIOT_VERSION.tar.gz
mkdir -p /var/www/chat.$DOMAIN_NAME/public
tar xf riot-v$RIOT_VERSION.tar.gz -C /var/www/chat.$DOMAIN_NAME/public --strip-components 1
sed -i -e "s/__DOMAIN__/$DOMAIN_NAME/g" /tmp/matrix-server/riot-config.json
cp /tmp/matrix-server/riot-config.json /var/www/chat.$DOMAIN_NAME/public/config.json
chown -R www-data:www-data /var/www/chat.$DOMAIN_NAME/

#############################
# Debian Unattended Upgrade #
#############################
DEBIAN_FRONTEND='noninteractive' apt-get -y install unattended-upgrades apt-listchanges
cp /tmp/matrix-server/debian-50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades
cp /tmp/matrix-server/debian-20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades

