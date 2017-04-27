# postgres-docker-replication-tut
Tutorial on Postgres high availability and replication through local docker setup using docker-compose.

The purpose of this tutorial is to walk you through the steps to setup streaming replication between a master and a single standby server. Through docker-compose you will spin up two postgres instances, one of them running with a script dumping data into a table named `entries`. Since `supervisord` is keeping the container up, you will be able to edit the config files live which will be applied after restarting postgres (You could also edit them before building the image, as they are found under `pfiles/master-conf/` and `pfiles/standby-conf/`).

The tutorial to set up the replication follows the steps from https://wiki.postgresql.org/wiki/Streaming_Replication

### 
***

1) If you don't have docker-compose installed, you will need to install it (I assume you already have docker).

```
brew install docker-compose
```
or go to https://docs.docker.com/compose/install/

2) After cloning the repo, in the root directory run the command below. This will build the two images, spin them up and detach from them.
```
docker-compose up -d --build
```
This will spin up:
* postgresdockerreplicationtut_standby_1
* postgresdockerreplicationtut_master_1
3) Connect to master and confirm postgres is running and data is being added to the table.
Connect to master:
```
docker exec -it postgresdockerreplicationtut_master_1 bash
```
Change to user postgres, connect to the server and show the tables.
```
# su postgres
# psql
> \dt
> SELECT * FROM entries;
```
If everything is working correctly you should see data in entries, there is a script writing random data to it every 3 seconds.

4) Create replication user, the standby will use this username and password when connecting to the master host to replicate, then exit the psql client.
```
 CREATE ROLE replication WITH REPLICATION PASSWORD 'password' LOGIN;
 \q
```
 
 5) Get the ip address of the standby server and give it permission to replicate off of master
 ```
ping standby #ctrl-c to terminate

vim /etc/postgresql/9.4/main/pg_hba.conf
# The standby server must connect with a user that has replication privileges.
# TYPE  DATABASE        USER            ADDRESS                 METHOD
  host  replication     replication     ${STANDBY_IP}/32         md5
```

6) Set up streaming replication parameters.
```
vim /etc/postgresql/9.4/main/postgresql.conf
# To enable read-only queries on a standby server, wal_level must be set to
# "hot_standby". But you can choose "archive" if you never connect to the
# server in standby mode.
wal_level = hot_standby

# Set the maximum number of concurrent connections from the standby servers.
max_wal_senders = 5

# To prevent the primary server from removing the WAL segments required for
# the standby server before shipping them, set the minimum number of segments
# retained in the pg_xlog directory. At least wal_keep_segments should be
# larger than the number of segments generated between the beginning of
# online-backup and the startup of streaming replication. If you enable WAL
# archiving to an archive directory accessible from the standby, this may
# not be necessary.
wal_keep_segments = 32

# Enable WAL archiving on the primary to an archive directory accessible from
# the standby. If wal_keep_segments is a high enough number to retain the WAL
# segments required for the standby server, this is not necessary.
archive_mode    = on
archive_command = 'cp %p /var/wal/%f'

```
7) Restart postgres and exit out of master host.
```
/etc/init.d/postgresql restart
exit
exit
```

