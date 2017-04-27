#!/usr/bin/env bash

# Create postgres data directory and run initdb if needed
# This is useful for docker volumes


mv /standby-conf/* /etc/postgresql/9.4/main/

mkdir -p /var/lib/postgresql/9.4/main