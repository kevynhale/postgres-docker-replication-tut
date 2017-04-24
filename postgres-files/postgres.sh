#!/usr/bin/env bash

# Create postgres data directory and run initdb if needed
# This is useful for docker volumes
if [ ! -e /var/lib/postgresql/9.4/main ]; then
    echo "Creating data directory"
    mkdir -p /var/lib/postgresql/9.4/main
    touch /var/lib/postgresql/firstrun
    echo "Initializing database files"
    /usr/lib/postgresql/9.4/bin/initdb -D /var/lib/postgresql/9.4/main/
fi

create_user () {
  if [ ! -e /var/lib/postgresql/firstrun ]; then
    mkdir -p /var/run/postgresql/9.4-main.pg_stat_tmp
    echo "Waiting for PostgreSQL to start"
    while [ ! -e /var/run/postgresql/9.4-main.pid ]; do
      inotifywait -q -q -e create /var/run/postgresql/
    done

    # We sleep here for 2 seconds to allow clean output, and speration from postgres startup messages
    sleep 2
    echo "Below are your configured options."
    echo -e "================\nUSER: $USER\nPASSWORD: $PASSWORD"
    psql -c "CREATE TABLE entries (did integer CHECK (did > 100), phrase text, state varchar(40));"
    psql -c "CREATE ROLE replication WITH REPLICATION PASSWORD 'password' LOGIN;"
 
    echo "ALTER USER :user WITH PASSWORD :'password' ;" | psql --set user=$USER --set password=$PASSWORD

    rm /var/lib/postgresql/firstrun
  fi
}


create_user &
exec /usr/lib/postgresql/9.4/bin/postgres -D /var/lib/postgresql/data -c config_file=/etc/postgresql/9.4/main/postgresql.conf