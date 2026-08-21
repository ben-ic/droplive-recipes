#!/bin/sh
set -eu

: "${GHOST_CONNECTION_HOST:?DropLive supplies the MySQL host}"
: "${GHOST_CONNECTION_PORT:?DropLive supplies the MySQL port}"
: "${GHOST_CONNECTION_USER:?DropLive supplies the MySQL user}"
: "${GHOST_CONNECTION_PASSWORD:?DropLive supplies the MySQL password}"
: "${GHOST_CONNECTION_DATABASE:?DropLive supplies the MySQL database}"

export database__client=mysql
export database__connection__host="$GHOST_CONNECTION_HOST"
export database__connection__port="$GHOST_CONNECTION_PORT"
export database__connection__user="$GHOST_CONNECTION_USER"
export database__connection__password="$GHOST_CONNECTION_PASSWORD"
export database__connection__database="$GHOST_CONNECTION_DATABASE"

exec docker-entrypoint.sh "$@"
