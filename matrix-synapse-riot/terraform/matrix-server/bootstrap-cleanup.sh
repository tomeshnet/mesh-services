#!/usr/bin/env bash

set -e

# Disable root login in sshd_config
echo "" >> /etc/ssh/sshd_config
sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

# Clean up the tmp directory
shred -u /tmp/matrix-server/*
rm -rf  /tmp/matrix-server/
