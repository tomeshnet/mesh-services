#!/usr/bin/env bash

DATAPASS=$1

# Create user and database
createuser synapse_user
psql -c "alter user synapse_user with encrypted password '$DATAPASS'"
psql -c "CREATE DATABASE synapse ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' template=template0 OWNER synapse_user"

