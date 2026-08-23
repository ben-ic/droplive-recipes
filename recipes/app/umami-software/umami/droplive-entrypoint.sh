#!/bin/sh
# Start Umami, then give it forty-five days of traffic to northstar-relay.invalid.
#
# WRITTEN AS ROWS, not collected. Umami's /api/send endpoint is its only import
# path and it stamps every event with the moment it arrives, so a demo seeded
# through it has a history one second long -- for an analytics tool, worse than
# being empty. The rows go in through `prisma db execute`, which is Umami's own
# migration tooling reading its own configured datasource, so nothing here needs
# a database client or a connection string of its own.
#
# The script is written to be safe to re-run: every insert carries ON CONFLICT DO
# NOTHING, keyed on identifiers derived from the world, so the same source always
# produces the same rows and a second run adds none.
set -eu

SEED=/usr/local/lib/droplive-umami-seed.sql
BASE="http://127.0.0.1:${PORT:-3000}"

seed() {
  [ -r "$SEED" ] || return 0

  # Ready, not merely listening: Umami runs its migrations during startup and the
  # heartbeat answers only once the schema the seed writes into exists.
  waited=0
  while [ "$waited" -lt 180 ]; do
    if wget -q -T 3 -O /dev/null "$BASE/api/heartbeat" 2>/dev/null; then break; fi
    sleep 1
    waited=$((waited + 1))
  done
  [ "$waited" -lt 180 ] || { echo "[droplive] umami did not become ready; skipping seed" >&2; return 0; }

  export PATH="/app/node_modules/.bin:$PATH"
  if prisma db execute --stdin <"$SEED" >/dev/null 2>&1; then
    echo "[droplive] wrote the Northstar traffic" >&2
  else
    echo "[droplive] umami refused the traffic" >&2
  fi
}

"$@" &
server_pid=$!
trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT

seed || echo "[droplive] seed failed; the app is still running" >&2

wait "$server_pid"
