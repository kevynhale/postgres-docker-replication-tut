# postgres-docker-replication-tut
Tutorial on Postgres high availability and replication through local docker setup using docker-compose.

The purpose of this tutorial is to walk you through the steps to setup streaming replication between a master and a single standby server. Through docker-compose you will spin up two postgres instances, one of them running with a script dumping data into a table named `entries`. Since `supervisord` is keeping the container, you will be able to edit the config files live which will be applied after restarting postgres.

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


