#!/bin/sh
set -eu

# droplive: generate=hex64 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=MEALIE_BOOTSTRAP_PASSWORD capability=owner-login username=owner@local.invalid
: "${MEALIE_BOOTSTRAP_PASSWORD:?DropLive must generate the initial owner password}"
: "${MEALIE_BOOTSTRAP_EMAIL:?The recipe must provide the initial owner email address}"
: "${BASE_URL:?DropLive must derive the public application URL}"

case "${MEALIE_BOOTSTRAP_PASSWORD}" in
  *[!A-Za-z0-9_-]*|'')
    echo "MEALIE_BOOTSTRAP_PASSWORD must contain at least 16 URL-safe characters" >&2
    exit 1
    ;;
esac

if [ "${#MEALIE_BOOTSTRAP_PASSWORD}" -lt 16 ]; then
  echo "MEALIE_BOOTSTRAP_PASSWORD must contain at least 16 URL-safe characters" >&2
  exit 1
fi

umask 077

# Run the exact release's migrations and first database seed offline. Traffic
# cannot arrive until both migration and secure owner rotation have succeeded.
timeout -s TERM 300 python -m mealie.db.init_db
timeout -s TERM 60 python /usr/local/lib/droplive-mealie-bootstrap-owner.py

# Add the demonstration recipes only to an empty recipe collection. The seed
# uses the supported local API after the service starts, so it does not depend
# on Mealie's private database schema.
if [ ! -e /app/data/droplive-recipes-seed-v1 ]; then
  "$@" &
  mealie_pid=$!
  trap 'kill "$mealie_pid" 2>/dev/null || true; wait "$mealie_pid" 2>/dev/null || true' EXIT INT TERM
  timeout -s TERM 120 python /usr/local/lib/droplive-mealie-seed-recipes.py
  touch /app/data/droplive-recipes-seed-v1
  wait "$mealie_pid"
  exit $?
fi

# The application retains only the password hash. Remove bootstrap inputs from
# the long-running process environment; BASE_URL remains required at runtime.
unset MEALIE_BOOTSTRAP_PASSWORD MEALIE_BOOTSTRAP_EMAIL
exec "$@"
