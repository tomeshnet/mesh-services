#!/usr/bin/env bash

SYNAPSE_VERSION=0.33.9
SERVER_NAME=$1
DATAPASS=$2

# Go home
cd $HOME

# Installation
virtualenv -p python2.7 ~/.synapse
source ~/.synapse/bin/activate
pip install --upgrade setuptools
pip install https://github.com/matrix-org/synapse/tarball/v$SYNAPSE_VERSION
cd ~/.synapse/

# Generate homeserver.yaml
python -B -m synapse.app.homeserver -c homeserver.yaml --generate-config --report-stats=no --server-name=$SERVER_NAME
sed -i -e "s/x_forwarded: false/x_forwarded: true/g" homeserver.yaml
sed -i -e "s/url_preview_enabled: False/url_preview_enabled: True/g" homeserver.yaml
sed -i -e "s/enable_group_creation: false/enable_group_creation: true/g" homeserver.yaml
sed -i -e "s/enable_registration: False/enable_registration: True/g" homeserver.yaml

echo "
url_preview_ip_range_blacklist:
 - '127.0.0.0/8'
 - '10.0.0.0/8'
 - '172.16.0.0/12'
 - '192.168.0.0/16'
 - '100.64.0.0/10'
 - '169.254.0.0/16'
 - '::1/128'
 - 'fe80::/64'
 - 'fc00::/7'
 ">> homeserver.yaml

sed -i '/# Database configuration/,/event_cache_size: "10K"/d' homeserver.yam
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

# Number of events to cache in memory.
event_cache_size: \"10K\"
" >> homeserver.yaml
echo "synctl_cache_factor: 0.02" >> homeserver.yaml

# Install lxml
pip install lxml

# Create a startup script
mkdir ~/bin/
cp /tmp/matrix-server/synapse-startup.sh ~/bin/startup.sh
sh -c '(crontab -l 2>/dev/null; echo "@reboot /home/synapse/bin/startup.sh") | crontab -'
