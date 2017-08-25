#!/usr/bin/env bash

#set -x

echo "$(basename "$0")"

##Do after down (clearing, backup, add env vars, etc)

MASK="SENTRY_SECRET_KEY"

if ! grep -qw "$MASK" .env ; then 
    #sed -i  -re "/^${MASK}=/d" .env
    # Generate Sentry secret key and update .env
    SECRETKEY=$(docker run --rm sentry config generate-secret-key)
    echo "$MASK=\"$SECRETKEY\"" >> .env
    echo "Key generated - Ok"
fi

