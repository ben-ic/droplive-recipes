#!/bin/sh
# Start MailDev, then deliver the Northstar company's mail to it.
#
# MailDev's own API only reads. The way anything gets into MailDev is the way an
# application under test puts it there: a plain SMTP conversation on port 1025.
# droplive-seed.js has that conversation with Node's own net module, so nothing is
# installed and nothing touches MailDev's store.
set -eu

MAIL=/usr/local/lib/droplive-maildev-mail
SEEDER=/usr/local/lib/droplive-maildev-seed.js
BASE="http://127.0.0.1:${MAILDEV_WEB_PORT:-1080}"

seed() {
  [ -d "$MAIL" ] || return 0
  [ -r "$SEEDER" ] || return 0

  # Ready, not merely listening: the SMTP listener opens after the web one does.
  waited=0
  while [ "$waited" -lt 60 ]; do
    if wget -q -T 3 -O /dev/null "$BASE/api/email" 2>/dev/null; then break; fi
    sleep 1
    waited=$((waited + 1))
  done
  [ "$waited" -lt 60 ] || { echo "[droplive] maildev did not become ready; skipping seed" >&2; return 0; }

  # IDEMPOTENT ON MAILDEV'S OWN MAILBOX. MailDev keeps messages for the life of the
  # process unless it is given a directory, so a restart normally starts empty --
  # but if anything is already there, it is left alone.
  if ! wget -q -T 5 -O - "$BASE/api/email" 2>/dev/null | grep -q '^\[\]$'; then
    echo "[droplive] maildev already holds messages; leaving them alone" >&2
    return 0
  fi

  node "$SEEDER" "$MAIL" "${MAILDEV_SMTP_PORT:-1025}"
}

"$@" &
server_pid=$!
trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT

seed || echo "[droplive] seed failed; the app is still running" >&2

wait "$server_pid"
