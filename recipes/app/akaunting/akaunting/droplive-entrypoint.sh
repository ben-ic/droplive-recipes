#!/bin/sh
set -eu

: "${APP_URL:?DropLive supplies the public origin}"
: "${DATABASE_URL:?DropLive supplies the MariaDB connection URL}"
: "${ADMIN_PASSWORD:?DropLive generates the Akaunting admin password}"

export DB_HOST="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo $u["host"] ?? "";')"
export DB_PORT="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo $u["port"] ?? "3306";')"
export DB_USERNAME="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo rawurldecode($u["user"] ?? "");')"
export DB_PASSWORD="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo rawurldecode($u["pass"] ?? "");')"
export DB_NAME="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo rawurldecode(ltrim($u["path"] ?? "", "/"));')"
: "${DB_HOST:?DropLive supplies the MariaDB host}"
: "${DB_NAME:?DropLive supplies the MariaDB database}"
: "${DB_USERNAME:?DropLive supplies the MariaDB user}"
: "${DB_PASSWORD:?DropLive supplies the MariaDB password}"

# Akaunting's Laravel image uses the MySQL PDO driver for MariaDB. The image
# otherwise copies the companion type name into DB_CONNECTION and rejects
# `mariadb` as an unsupported Laravel driver.
export DB_CONNECTION=mysql

exec /usr/local/bin/akaunting.sh "$@"
