#!/bin/sh
set -eu

# Listmonk uses mixed-case configuration names. DropLive binds portable
# upper-case names, so map the reviewed companion values at the recipe edge.
export LISTMONK_db__host="${DROPLIVE_LISTMONK_DB_HOST:?missing database host}"
export LISTMONK_db__port="${DROPLIVE_LISTMONK_DB_PORT:?missing database port}"
export LISTMONK_db__database="${DROPLIVE_LISTMONK_DB_DATABASE:?missing database name}"
export LISTMONK_db__user="${DROPLIVE_LISTMONK_DB_USER:?missing database user}"
export LISTMONK_db__password="${DROPLIVE_LISTMONK_DB_PASSWORD:?missing database password}"

./listmonk --install --idempotent --yes --config ''
./listmonk --upgrade --yes --config ''
exec ./listmonk --config ''
