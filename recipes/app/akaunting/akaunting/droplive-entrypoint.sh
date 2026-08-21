#!/bin/sh
set -eu

: "${APP_URL:?DropLive supplies the public origin}"
: "${DB_HOST:?DropLive supplies the MariaDB host}"
: "${DB_PORT:?DropLive supplies the MariaDB port}"
: "${DB_NAME:?DropLive supplies the MariaDB database}"
: "${DB_USERNAME:?DropLive supplies the MariaDB user}"
: "${DB_PASSWORD:?DropLive supplies the MariaDB password}"
: "${ADMIN_PASSWORD:?DropLive generates the Akaunting admin password}"

exec /usr/local/bin/akaunting.sh "$@"
