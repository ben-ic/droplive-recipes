#!/bin/sh
set -eu

if [ -z "${DROPLIVE_ADMIN_PASSWORD:-}" ] || [ -z "${DROPLIVE_STABLE_URL:-}" ] || \
   [ -z "${DROPLIVE_FAILING_URL:-}" ] || [ -z "${DROPLIVE_FLAPPING_URL:-}" ]; then
  echo "Uptime Kuma setup requires its DropLive password and target bindings" >&2
  exit 64
fi

"$@" &
server_pid=$!
trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT

node /usr/local/lib/droplive-uptime-kuma-seed.cjs
wait "$server_pid"
