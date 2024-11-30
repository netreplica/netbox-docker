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

1. Shutdown all instances:

```Shell
INSTANCE=main
PREVIOUS=v35
CURRENT=v36
LATEST=v37
REPO_DIR="$(pwd)"

./nbctl.sh -d "${INSTANCE}_${PREVIOUS}"
./nbctl.sh -d "${INSTANCE}_${LATEST}"
```

2. Backup `latest` DBs:

```Shell
cd /mnt/netbox/"${INSTANCE}_${LATEST}"
bash -c "eval \"$(cat netbox.env | grep DB_)\"; pg_dump --exclude-table-data=extras_objectchange \"host=\${DB_HOST} dbname=\${DB_NAME} user=\${DB_USER} password=\${DB_PASSWORD}\"" > backup.sql
cd /mnt/netbox
```

3. Move the versions:

```Shell
PREVIOUS=v36
CURRENT=v37
LATEST=v40
cp -r "${INSTANCE}_${CURRENT}" "${INSTANCE}_${LATEST}"
```

4. Make a clone of the `current` DB into `latest`. You will need a password for `postgres` superuser.

```Shell
cd /mnt/netbox/"${INSTANCE}_${LATEST}"
export DB_NAME_CURRENT=$(cat netbox.env | grep DB_NAME | cut -d= -f2)
cat netbox.env | sed "s/_${CURRENT}/_${LATEST}/" > netbox.env.new
mv netbox.env.new netbox.env
bash -c "eval \"$(cat netbox.env | grep DB_)\"; psql -h \${DB_HOST} -U postgres -W -c \"CREATE DATABASE \${DB_NAME} WITH TEMPLATE \${DB_NAME_CURRENT} OWNER \${DB_USER};\""
```

5. Update `netbox.env` files for each instance to use newly created DB name as well as unique REDIS DB IDs.

```
REDIS_DATABASE=0
REDIS_CACHE_DATABASE=1
```

6. Update image version in `docker-compose.override.yml` to match images from `docker-compose.yml`, use correct path to the `env_file` and different TCP ports than the `current` instance:

```
services:
  netbox:
    image: docker.io/netboxcommunity/netbox:${VERSION-v4.0-2.9.1}
    ports:
      - 8140:8080
    env_file: /mnt/netbox/main_v40/netbox.env
    networks:
      - redis-net
  netbox-worker:
    image: docker.io/netboxcommunity/netbox:${VERSION-v4.0-2.9.1}
    env_file: /mnt/netbox/main_v40/netbox.env
    networks:
      - redis-net
  netbox-housekeeping:
    image: docker.io/netboxcommunity/netbox:${VERSION-v4.0-2.9.1}
    env_file: /mnt/netbox/main_v40/netbox.env
    networks:
      - redis-net

networks:
  redis-net:
    driver: bridge
    name: redis-net
```

8. Pull the `latest` images

```Shell
cd "${REPO_DIR}"
docker compose -f docker-compose-app.yml -f "/mnt/netbox/${INSTANCE}_${LATEST}/docker-compose.override.yml" pull
```

9. Start `latest` instances

```Shell
./nbctl.sh -u redis
./nbctl.sh -u "${INSTANCE}_${PREVIOUS}"
./nbctl.sh -u "${INSTANCE}_${CURRENT}"
./nbctl.sh -u "${INSTANCE}_${LATEST}"
```
