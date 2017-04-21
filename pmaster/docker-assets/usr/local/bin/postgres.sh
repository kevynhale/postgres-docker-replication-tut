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
    echo -e "================\nUSER: $USER\nPASSWORD: $PASSWORD\nSCHEMA: $SCHEMA\nENCODING: $ENCODING\nPOSTGIS: $POSTGIS\n================"
    # Ensure template1 gets updated with proper encoding
    psql -c "UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'template1';"
    psql -c "DROP DATABASE template1;"
    psql -c "CREATE DATABASE template1 WITH TEMPLATE = template0 ENCODING = '$ENCODING';"
    psql -c "UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template1';"
    psql -d 'template1' -c "VACUUM FREEZE;"
    psql -c "CREATE TABLE distributors (did integer CHECK (did > 100), name varchar(40));"
    if [ "$USER" == "postgres" ]; then
      echo "ALTER USER :user WITH PASSWORD :'password' ;" | psql --set user=$USER --set password=$PASSWORD
      if [ "$SCHEMA" != "postgres" ]; then
        createdb -E $ENCODING -T template0 $SCHEMA
      fi
    else
      echo "CREATE USER :user WITH SUPERUSER PASSWORD :'password' ;" | psql --set user=$USER --set password=$PASSWORD && createdb -E $ENCODING -T template0 $SCHEMA
    fi

    # Create .pgpass for use with backups
    echo "localhost:5432:*:$USER:$PASSWORD" > /var/lib/postgresql/.pgpass
    chmod 0600 /var/lib/postgresql/.pgpass

    # Update pg_backup with proper user
    sed -i "s/^USERNAME=.*$/USERNAME=$USER/" /usr/local/etc/pg_backup.config


    rm /var/lib/postgresql/firstrun
  fi
}

crontab -l | { cat; echo "* * * * * postgres psql -c 'INSERT INTO distributors (did, name) VALUES (\'120\', \'kevyn\');'"; } | crontab -

create_user &
exec /usr/lib/postgresql/9.4/bin/postgres -D /var/lib/postgresql/data -c config_file=/etc/postgresql/9.4/main/postgresql.conf