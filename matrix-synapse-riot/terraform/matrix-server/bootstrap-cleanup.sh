#!/usr/bin/env bash

set -e

# Disable root login in sshd_config
sed -i -e "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config

# Clean up the tmp directory
shred -u /tmp/matrix-server/*
rm -rf  /tmp/matrix-server/
