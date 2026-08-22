#!/bin/sh
set -eu

# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=PB_ADMIN_PASSWORD capability=owner-login username=droplive-owner@local.invalid
: "${PB_ADMIN_PASSWORD:?DropLive must generate the initial PocketBase owner password}"

if [ ! -e /pb_data/data.db ]; then
  echo "[pocketbase-init] Creating the initial owner account."
  umask 077
  /usr/local/bin/pocketbase superuser create \
    droplive-owner@local.invalid \
    "$PB_ADMIN_PASSWORD" \
    --dir=/pb_data
fi

unset PB_ADMIN_PASSWORD
exec /usr/local/bin/entrypoint.sh "$@"
