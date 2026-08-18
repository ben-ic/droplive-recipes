#!/bin/sh
set -eu

# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=MEALIE_BOOTSTRAP_PASSWORD capability=owner-login username=owner@local.invalid
: "${MEALIE_BOOTSTRAP_PASSWORD:?DropLive must generate the initial owner password}"
: "${MEALIE_BOOTSTRAP_EMAIL:?The recipe must provide the initial owner email address}"
: "${BASE_URL:?DropLive must derive the public application URL}"

case "${MEALIE_BOOTSTRAP_PASSWORD}" in
  *[!A-Za-z0-9_-]*|'')
    echo "MEALIE_BOOTSTRAP_PASSWORD must contain exactly 16 URL-safe characters" >&2
    exit 1
    ;;
esac

if [ "${#MEALIE_BOOTSTRAP_PASSWORD}" -ne 16 ]; then
  echo "MEALIE_BOOTSTRAP_PASSWORD must contain exactly 16 URL-safe characters" >&2
  exit 1
fi

umask 077

# Run the exact release's migrations and first database seed offline. Traffic
# cannot arrive until both migration and secure owner rotation have succeeded.
timeout -s TERM 300 python -m mealie.db.init_db
timeout -s TERM 60 python /usr/local/lib/droplive-mealie-bootstrap-owner.py

# The application retains only the password hash. Remove bootstrap inputs from
# the long-running process environment; BASE_URL remains required at runtime.
unset MEALIE_BOOTSTRAP_PASSWORD MEALIE_BOOTSTRAP_EMAIL
exec "$@"
