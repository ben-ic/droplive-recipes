#!/bin/sh
set -eu

if [ -z "${DROPLIVE_COMPANY_URL:-}" ] || [ -z "${DROPLIVE_CHANGING_URL:-}" ]; then
  echo "changedetection.io setup requires its DropLive target bindings" >&2
  exit 64
fi

mkdir -p /datastore
if [ ! -e /datastore/url-watches.json ]; then
  cp /usr/local/share/droplive-changedetection-datastore.json /datastore/url-watches.json
fi

"$@" &
server_pid=$!
trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT

python /usr/local/lib/droplive-changedetection-seed.py
wait "$server_pid"
