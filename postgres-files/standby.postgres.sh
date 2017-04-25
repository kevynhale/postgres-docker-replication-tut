#!/usr/bin/env bash

# Create postgres data directory and run initdb if needed
# This is useful for docker volumes

if [ ! -e /var/lib/postgresql/9.4/main ]; then

    mv /standby-conf/* /etc/postgresql/9.4/main/
    echo "Creating data directory"
    mkdir -p /var/lib/postgresql/9.4/main
    touch /var/lib/postgresql/firstrun
    echo "Initializing database files"
    
    sleep 60 # Wait for master to set itself up.
    echo "172.25.0.2:5432:replication:replication:password" >> ~/.pgpass
    chmod 0600 ~/.pgpass
    pg_basebackup -h master -D /var/lib/postgresql/9.4/main -P -U replication --xlog-method=stream
    /var/lib/postgresql/9.4/main/recovery.conf << EOF
    standby_mode = 'on'
    primary_conninfo = 'host=master port=5432 user=replication password=password'
    trigger_file = '/tmp/postgresql.trigger'
EOF

    rm /var/lib/postgresql/firstrun

fi

exec /etc/init.d/postgresql start