#!/bin/sh
# Start Mailpit, then hand it the Northstar company's mail.
#
# `mailpit ingest` is Mailpit's own import command: it reads a folder of RFC 822
# files and delivers each one over SMTP to the running server, which is the same
# path any application under test uses. Nothing here touches Mailpit's store.
set -eu

MAIL=/usr/local/lib/droplive-mailpit-mail
BASE="http://127.0.0.1:${MP_UI_BIND_PORT:-8025}"

seed() {
  [ -d "$MAIL" ] || return 0

  # Ready, not merely listening: the SMTP listener answers after the UI does.
  waited=0
  while [ "$waited" -lt 60 ]; do
    if wget -q -T 3 -O /dev/null "$BASE/api/v1/info" 2>/dev/null; then break; fi
    sleep 1
    waited=$((waited + 1))
  done
  [ "$waited" -lt 60 ] || { echo "[droplive] mailpit did not become ready; skipping seed" >&2; return 0; }

  # IDEMPOTENT ON MAILPIT'S OWN COUNT. Mailpit keeps its messages in memory unless
  # it is given a database, so a restart normally starts empty and this ingests
  # again -- but if a store did survive, the mail is already there.
  if ! wget -q -T 5 -O - "$BASE/api/v1/messages?limit=1" 2>/dev/null | grep -q '"total":0'; then
    echo "[droplive] mailpit already holds messages; leaving them alone" >&2
    return 0
  fi

  /mailpit ingest "$MAIL" >/dev/null 2>&1 ||
    { echo "[droplive] mailpit refused the ingest" >&2; return 0; }
  echo "[droplive] ingested the Northstar mail" >&2
}

"$@" &
server_pid=$!
trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT

seed || echo "[droplive] seed failed; the app is still running" >&2

wait "$server_pid"
