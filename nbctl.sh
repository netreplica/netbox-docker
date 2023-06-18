#!/bin/bash

function usage {
  echo "Usage: $(basename $0) [-u|d] <instance> [-h]" 2>&1
  echo '   -u <instance>  bring up netbox docker instance' 2>&1
  echo '   -d <instance>  shut down netbox docker instance' 2>&1
  echo '   -h         show usage' 2>&1
}

# list of arguments expected in the input
optstring="u:d:h"

while getopts ${optstring} arg; do
  case ${arg} in
    s)
      # bring up netbox docker instance
      docker-compose -f ./docker-compose-redis.yml up -d
      docker-compose -p "${OPTARG}" -f ./docker-compose-app.yml -f "/mnt/netbox/${OPTARG}/docker-compose.override.yml" up -d
      ;;
    r)
      # shut down netbox docker instance
      docker-compose -p "${OPTARG}" -f ./docker-compose-app.yml -f "/mnt/netbox/${OPTARG}/docker-compose.override.yml" down
      docker-compose -f ./docker-compose-redis.yml down
      ;;
    h)
      usage
      exit
      ;;
    ?)
      usage
      exit 2
      ;;
  esac
done


