#!/usr/bin/env bash

set -u

source .env

if [ "$DOCKER_DEBUG_SCRIPTS" = '1' ]; then
    set -x
fi

echo "$(basename "$0")"


./bin/_create_key.sh

# Databases
docker-compose up -d redis postgres sentry

# Initial setup
docker-compose exec sentry sentry upgrade

# Run the remaining containers (Celery)
docker-compose up -d
#docker-compose up $@
./bin/_up.sh
# Run bash in sentry as root
#docker-compose exec --user=root sentry bash
