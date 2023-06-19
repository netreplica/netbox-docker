# Upgrading instructions for netreplica deployments

## Overview

To maintain ability to test netreplica software with previous versions of NetBox, the upgrade process follows these steps:

1. We will refer to the most recent release of netbox that is being currently used for testing netreplica software as `current`
2. We will refer to the version of netbox we're upgrading to as `latest`
3. Shutdown all instances of netbox that are using the DBs of the `current` version
4. Backup `current` DBs
5. Make a clone of the `current` DBs to be used with the `latest` version
6. Make copies of `current` environment directories & files for each netbox instance to be upgrade to the `latest`. Use new instance naming to reflect the `latest` version number as major.minor
7. Apply any necessary modifications to the `latest` environment files

## Prerequisites

1. PostgreSQL client

```Shell
sudo apt-get update
sudo apt install postgresql-client
```

## Step-by-step

1. Shutdown all `current` instances. Here and below, we assume the instance name is `INSTANCE1` and the `latest` version is `3.5`

```Shell
./nbctl.sh -d INSTANCE1
```

2. Backup `current` DBs:

```Shell
cd /mnt/netbox/INSTANCE1
bash -c "eval \"$(cat netbox.env | grep DB_)\"; pg_dump --exclude-table-data=extras_objectchange \"host=\${DB_HOST} dbname=\${DB_NAME} user=\${DB_USER} password=\${DB_PASSWORD}\"" > backup.sql
cd /mnt/netbox
```

3. Make a clone of the `current` DBs. You will need a password for `postgres` superuser.

> WARNING. This appends `_v35` at the end of the `current` db name without stripping any existing versions. Requires improvement.

```Shell
cd /mnt/netbox/INSTANCE1
bash -c "eval \"$(cat netbox.env | grep DB_)\"; psql -h \${DB_HOST} -U postgres -W -c \"CREATE DATABASE \${DB_NAME}_v35 WITH TEMPLATE \${DB_NAME} OWNER \${DB_USER};\""
cd /mnt/netbox
```

4. Make copies of `current` environment directories & files

```Shell
cp -r INSTANCE1 INSTANCE1_v35
```

5. Update `netbox.env` files for each instance to use newly created DB name as well as unique REDIS DB IDs. Use `latest` version as a prefix for REDIS:

```
DB_NAME=INSTANCE1_v35
REDIS_DATABASE=3510
REDIS_CACHE_DATABASE=3511
```

6. Update image version in `docker-compose-app.yml` as well as in `docker-compose-redis.yml` to match images from `docker-compose.yml`.

7. Pull the `latest` images

```Shell
docker-compose pull
```

7. Start `latest` instances

```Shell
./nbctl.sh -u redis
./nbctl.sh -u INSTANCE1_v35
```