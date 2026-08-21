#!/bin/sh
set -eu

: "${APP_URL:?DropLive supplies the public origin}"
: "${DATABASE_URL:?DropLive supplies the PostgreSQL connection URL}"
export BASEROW_PUBLIC_URL="$APP_URL"

: "${DATABASE_URL:?DropLive supplies the PostgreSQL connection URL}"
DATABASE_REST="${DATABASE_URL#*://}"
DATABASE_AUTH="${DATABASE_REST%%@*}"
DATABASE_HOST_PORT_PATH="${DATABASE_REST#*@}"
DATABASE_USER="${DATABASE_AUTH%%:*}"
DATABASE_PASSWORD="${DATABASE_AUTH#*:}"
DATABASE_HOST_PORT="${DATABASE_HOST_PORT_PATH%%/*}"
DATABASE_NAME="${DATABASE_HOST_PORT_PATH#*/}"
DATABASE_HOST="${DATABASE_HOST_PORT%%:*}"
DATABASE_PORT="${DATABASE_HOST_PORT#*:}"
: "${DATABASE_PORT:?DropLive supplies the PostgreSQL port}"
: "${DATABASE_HOST:?DropLive supplies the PostgreSQL host}"
: "${DATABASE_USER:?DropLive supplies the PostgreSQL user}"
: "${DATABASE_PASSWORD:?DropLive supplies the PostgreSQL password}"
: "${DATABASE_NAME:?DropLive supplies the PostgreSQL database}"

exec /baserow.sh "$@"
