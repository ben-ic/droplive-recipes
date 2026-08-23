#!/bin/sh
# Start Umami, give it the site's history, and keep the site alive while the
# demo runs.
#
# Umami is the one seeded app whose front page is a fixed recent window: it
# opens on the last twenty-four hours. History shipped as rows written at
# authoring time is therefore stale the day it is built and empty a month
# later, so it is generated here instead, against this container's clock. The
# history always ends at this moment, weekends fall on weekends, and the
# export incident is always about three weeks ago.
#
# The history is WRITTEN AS ROWS, not collected: /api/send stamps every event
# with the moment it arrives, which is exactly wrong for a past and exactly
# right for a present. So the past goes in through `prisma db execute`, which
# is Umami's own migration tooling reading its own configured datasource, and
# the present goes in through /api/send, which is the collector every real
# Umami site uses. Both draw from the same page and referrer model, so Realtime
# shows people reading the pages the charts are counting.
#
# Re-running is safe: every identifier is derived from a day offset rather than
# a date and every insert carries ON CONFLICT DO NOTHING, so a restart inside
# the same container adds nothing.
set -eu

TRAFFIC=/usr/local/lib/droplive-umami-traffic.js
BASE="http://127.0.0.1:${PORT:-3000}"

seed() {
  [ -r "$TRAFFIC" ] || return 0

  # Ready, not merely listening: Umami runs its migrations during startup and
  # the heartbeat answers only once the schema the history writes into exists.
  waited=0
  while [ "$waited" -lt 180 ]; do
    if wget -q -T 3 -O /dev/null "$BASE/api/heartbeat" 2>/dev/null; then break; fi
    sleep 1
    waited=$((waited + 1))
  done
  [ "$waited" -lt 180 ] || { echo "[droplive] umami did not become ready; skipping seed" >&2; return 0; }

  export PATH="/app/node_modules/.bin:$PATH"
  if node "$TRAFFIC" --sql | prisma db execute --stdin >/dev/null 2>&1; then
    echo "[droplive] wrote the Northstar history" >&2
  else
    echo "[droplive] umami refused the history" >&2
    return 0
  fi

  # From here the site keeps receiving visits, so the current day goes on
  # filling and Realtime is not a dead page.
  node "$TRAFFIC" --live "$BASE" >/dev/null 2>&1 &
  echo "[droplive] visits continue to arrive" >&2
}

"$@" &
server_pid=$!
trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT

seed || echo "[droplive] seed failed; the app is still running" >&2

wait "$server_pid"
