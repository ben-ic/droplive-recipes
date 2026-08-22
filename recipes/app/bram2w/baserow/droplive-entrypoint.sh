#!/bin/sh
set -eu

: "${APP_URL:?DropLive supplies the public origin}"
: "${DATABASE_URL:?DropLive supplies the PostgreSQL connection URL}"

exec env \
  BASEROW_PUBLIC_URL="$APP_URL" \
  PRIVATE_BACKEND_URL="http://127.0.0.1:8000" \
  PRIVATE_WEB_FRONTEND_URL="http://127.0.0.1:3000" \
  DATABASE_HOST="$(python3 -c 'from os import environ; from urllib.parse import urlsplit; print(urlsplit(environ["DATABASE_URL"]).hostname or "")')" \
  DATABASE_PORT="$(python3 -c 'from os import environ; from urllib.parse import urlsplit; print(urlsplit(environ["DATABASE_URL"]).port or 5432)')" \
  DATABASE_USER="$(python3 -c 'from os import environ; from urllib.parse import urlsplit, unquote; print(unquote(urlsplit(environ["DATABASE_URL"]).username or ""))')" \
  DATABASE_PASSWORD="$(python3 -c 'from os import environ; from urllib.parse import urlsplit, unquote; print(unquote(urlsplit(environ["DATABASE_URL"]).password or ""))')" \
  DATABASE_NAME="$(python3 -c 'from os import environ; from urllib.parse import urlsplit; print(urlsplit(environ["DATABASE_URL"]).path.lstrip("/"))')" \
  /baserow.sh "$@"
