#!/usr/bin/env bash
set -e
sleep 10
source /home/synapse/.synapse/bin/activate
cd /home/synapse/.synapse/
/home/synapse/.synapse/bin/synctl start
