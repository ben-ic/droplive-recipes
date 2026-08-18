#!/bin/sh
set -eu

# Upstream falls back to a known development secret, which it rejects in
# production. Fail closed so Automatic must satisfy both ownership contracts.
# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=AUTH_SECRET
: "${AUTH_SECRET:?DropLive must generate AUTH_SECRET}"
: "${APP_BASE_URL:?DropLive must derive APP_BASE_URL from the public origin}"

if [ "${#AUTH_SECRET}" -lt 32 ]; then
  echo "AUTH_SECRET must contain at least 32 characters" >&2
  exit 1
fi

case "${APP_BASE_URL}" in
  https://*) ;;
  *)
    echo "APP_BASE_URL must be the assigned public HTTPS origin" >&2
    exit 1
    ;;
esac

# The official image seeds these paths, but a fresh DropLive managed volume is
# deliberately empty. This remains non-root and fails immediately if ownership
# or mount permissions are wrong.
umask 077
mkdir -p /app/app-data/db /app/app-data/documents
test -w /app/app-data

exec /usr/local/bin/docker-entrypoint.sh "$@"
