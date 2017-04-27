# Postgres Replication Tutorial
Tutorial on Postgres high availability and replication through local docker setup using docker-compose.

The purpose of this tutorial is to walk you through the steps to setup streaming replication between a master and a single standby server. Through docker-compose you will spin up two postgres instances, one of them running with a script dumping data into a table named `entries`. Since `supervisord` is keeping the container up, you will be able to edit the config files live which will be applied after restarting postgres (You could also edit them before building the image, as they are found under `pfiles/master-conf/` and `pfiles/standby-conf/`).

The tutorial to set up the replication follows the steps from https://wiki.postgresql.org/wiki/Streaming_Replication

Follow the instruction here https://github.com/kevynhale/postgres-docker-replication-tut/blob/master/Dockerfile#L21-L23 and rebuild if you want it to come up with replciation already configured. The files under `pfiles-replication` have been scripted to spin it up with the replication commands and settings found below.
### 
***

1) If you don't have docker-compose installed, you will need to install it (I assume you already have docker).

```bash
brew install docker-compose
```
or go to https://docs.docker.com/compose/install/

2) After cloning the repo, in the root directory run the command below. This will build the two images, spin them up and detach from them.
```bash
docker-compose up -d --build
```
This will spin up:
* postgresdockerreplicationtut_standby_1
* postgresdockerreplicationtut_master_1
3) Connect to master and confirm postgres is running and data is being added to the table.
Connect to master:
```BASH
docker exec -it postgresdockerreplicationtut_master_1 bash
```
Change to user postgres, connect to the server and show the tables.
```BASH
$ su postgres
$ psql
> \dt
> SELECT * FROM entries;
```
If everything is working correctly you should see data in entries, there is a script writing random data to it every 3 seconds.

4) Create replication user, the standby will use this username and password when connecting to the master host to replicate, then exit the psql client.
```SQL
 CREATE ROLE replication WITH REPLICATION PASSWORD 'password' LOGIN;
 \q
```
 
 5) Get the ip address of the standby server and give it permission to replicate off of master
 ```BASH
ping standby #ctrl-c to terminate

vim /etc/postgresql/9.4/main/pg_hba.conf
# The standby server must connect with a user that has replication privileges.
# TYPE  DATABASE        USER            ADDRESS                 METHOD
  host  replication     replication     ${STANDBY_IP}/32         md5
```

6) Set up streaming replication parameters.
```BASH
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
```BASH
/etc/init.d/postgresql restart
exit
exit
```

8) Connect to standby and change to postgres user.
```BASH
docker exec -it postgresdockerreplicationtut_standby_1 bash
su postgres
```

9) Stream a copy of master to your data directory. The directory mentioned below should be empty. This will ask for a password which is `password`. This should be quick as our master db is tiny and is on the same box.
```BASH
rm -rf /var/lib/postgresql/9.4/main/*
pg_basebackup -h master -D /var/lib/postgresql/9.4/main -P -U replication --xlog-method=stream
```

10) Create a recovery file to stream new data. You will need to change back to root to create it. Change the owner to postgres.
```BASH
vim /var/lib/postgresl/9.4/main/recovery.conf
#if permissions are giving you hard time creating the file, try creating it with touch /var/lib/postgresl/9.4/main/recovery.conf and then editing it.
standby_mode = 'on'
primary_conninfo = 'host=master port=5432 user=replication password=password'
trigger_file = '/tmp/postgresql.trigger'

chown postgres:postgres /var/lib/postgresl/9.4/main/recovery.conf
```

11) Edit postgresql.conf and turn hot_standby to on. Restart postgres. Confirm replication is working. Do this as postgres user.
```BASH
vim /etc/postgresql/9.4/main/postgresql.conf
hot_standby = on
```
```BASH
/etc/init.d/postgresql restart
psql
> select count(*) from entries;
> select count(*) from entries;
```
The number being returned will be incrementing of replication is working. Any change made to master will affect the standby. Now you have a cluster up and running that you can experiment on!

To spin down the containers simply run `docker-compose down`.
