#!/bin/sh
set -u

: "${JWT_SECRET:?DropLive must generate JWT_SECRET}"
: "${LIFTTRACE_OWNER_PASSWORD:?DropLive must generate the LiftTrace owner password}"

mkdir -p /data/db /data/uploads

/usr/local/bin/docker-entrypoint.sh "$@" &
server_pid=$!
trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT

if node /usr/local/lib/droplive-lifttrace-seed.mjs; then
  echo "[droplive] LiftTrace demo is ready"
else
  echo "[droplive] LiftTrace seed failed; the app is still running" >&2
fi

wait "$server_pid"
