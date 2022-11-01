#!/bin/bash

set -e

if [ ! -f "$FUSEKI_BASE/shiro.ini" ]; then
    cp "$FUSEKI_HOME/shiro.ini" "$FUSEKI_BASE/shiro.ini"
fi

mkdir -p "$FUSEKI_BASE/configuration"

for path in "$FUSEKI_HOME"/dataset-config/*.ttl; do
    if [ ! -f "$FUSEKI_BASE/configuration/$(basename "$path")" ]; then
        cp "$path" "$FUSEKI_BASE/configuration/"
    fi
done

if [ ! -f "$FUSEKI_BASE/configuration/dogs.ttl" ]; then
    mkdir -p "$FUSEKI_BASE/configuration"
    cp "$FUSEKI_HOME/dogs-config.ttl" "$FUSEKI_BASE/configuration/dogs.ttl"
fi

if [ -n "$ADMIN_PASSWORD" ]; then
    export ADMIN_PASSWORD
    # shellcheck disable=SC2016
    envsubst '${ADMIN_PASSWORD}' \
        < "$FUSEKI_BASE/shiro.ini" > "$FUSEKI_BASE/shiro.ini.$$" \
        && mv "$FUSEKI_BASE/shiro.ini.$$" "$FUSEKI_BASE/shiro.ini"
    unset ADMIN_PASSWORD # Don't keep it in memory
    export ADMIN_PASSWORD
fi

# fork
exec "$@" &

# Wait until server is up
while [[ $(curl -I http://localhost:8080 2> /dev/null | head -n 1 | cut -d$' ' -f2) != '200' ]]; do
    sleep 1s
done

# rejoin our exec
wait
