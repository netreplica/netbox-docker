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
    u)
      # bring up netbox docker instance
      if [ "${OPTARG}" = "redis" ]
      then
        docker-compose -f ./docker-compose-redis.yml up -d
      else
        docker-compose -p "${OPTARG}" -f ./docker-compose-app.yml -f "/mnt/netbox/${OPTARG}/docker-compose.override.yml" up -d
      fi
      exit
      ;;
    d)
      # shut down netbox docker instance
      if [ "${OPTARG}" = "redis" ]
      then
        docker-compose -f ./docker-compose-redis.yml down
      else
        docker-compose -p "${OPTARG}" -f ./docker-compose-app.yml -f "/mnt/netbox/${OPTARG}/docker-compose.override.yml" down
      fi
      exit
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

usage
exit 2
