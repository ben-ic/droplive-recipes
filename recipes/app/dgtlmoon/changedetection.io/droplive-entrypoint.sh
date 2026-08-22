#!/bin/sh
set -eu

if { [ -n "${DROPLIVE_COMPANY_URL:-}" ] && [ -z "${DROPLIVE_CHANGING_URL:-}" ]; } || \
   { [ -z "${DROPLIVE_COMPANY_URL:-}" ] && [ -n "${DROPLIVE_CHANGING_URL:-}" ]; }; then
  echo "changedetection.io setup received an incomplete DropLive seed environment" >&2
  exit 64
fi

mkdir -p /datastore
if [ ! -e /datastore/url-watches.json ]; then
  cp /usr/local/share/droplive-changedetection-datastore.json /datastore/url-watches.json
fi

"$@" &
server_pid=$!
trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT

if [ -n "${DROPLIVE_COMPANY_URL:-}" ]; then
  python /usr/local/lib/droplive-changedetection-seed.py
fi
wait "$server_pid"
