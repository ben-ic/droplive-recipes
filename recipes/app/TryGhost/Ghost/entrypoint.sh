#!/bin/sh
set -eu

: "${GHOST_DB_HOST:?DropLive supplies the MySQL host}"
: "${GHOST_DB_PORT:?DropLive supplies the MySQL port}"
: "${GHOST_DB_USER:?DropLive supplies the MySQL user}"
: "${GHOST_DB_PASSWORD:?DropLive supplies the MySQL password}"
: "${GHOST_DB_DATABASE:?DropLive supplies the MySQL database}"

export database__client=mysql
export database__connection__host="$GHOST_DB_HOST"
export database__connection__port="$GHOST_DB_PORT"
export database__connection__user="$GHOST_DB_USER"
export database__connection__password="$GHOST_DB_PASSWORD"
export database__connection__database="$GHOST_DB_DATABASE"

exec docker-entrypoint.sh "$@"
