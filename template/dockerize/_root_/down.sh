#!/usr/bin/env bash

echo "$(basename "$0")"

docker-compose down $@
./bin/_down.sh
