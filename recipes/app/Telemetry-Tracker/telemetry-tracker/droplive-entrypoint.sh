#!/bin/sh
set -eu

: "${DATABASE_URL:?DropLive supplies the PostgreSQL companion URL}"
: "${TELEMETRY_OWNER_PASSWORD:?DropLive supplies the generated owner password}"

cd /app/api
node node_modules/prisma/build/index.js migrate deploy
node droplive-seed.mjs

node dist/index.js &
api_pid=$!

cd /app/dashboard
node node_modules/next/dist/bin/next start --hostname 0.0.0.0 --port 3000 &
dashboard_pid=$!

stop() {
  kill -TERM "$api_pid" "$dashboard_pid" 2>/dev/null || true
}
trap stop TERM INT EXIT

while kill -0 "$api_pid" 2>/dev/null && kill -0 "$dashboard_pid" 2>/dev/null; do
  sleep 2
done

wait "$api_pid" 2>/dev/null || status=$?
wait "$dashboard_pid" 2>/dev/null || status=${status:-$?}
exit "${status:-1}"
