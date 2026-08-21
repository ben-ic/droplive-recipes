#!/bin/sh
set -eu

: "${APP_URL:?DropLive supplies the public origin}"
: "${DATABASE_URL:?DropLive supplies the PostgreSQL connection URL}"
export BASEROW_PUBLIC_URL="$APP_URL"

export DATABASE_HOST="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo $u["host"] ?? "";')"
export DATABASE_PORT="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo $u["port"] ?? "5432";')"
export DATABASE_USER="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo rawurldecode($u["user"] ?? "");')"
export DATABASE_PASSWORD="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo rawurldecode($u["pass"] ?? "");')"
export DATABASE_NAME="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo rawurldecode(ltrim($u["path"] ?? "", "/"));')"
: "${DATABASE_HOST:?DropLive supplies the PostgreSQL host}"
: "${DATABASE_USER:?DropLive supplies the PostgreSQL user}"
: "${DATABASE_PASSWORD:?DropLive supplies the PostgreSQL password}"
: "${DATABASE_NAME:?DropLive supplies the PostgreSQL database}"

exec /baserow.sh "$@"
