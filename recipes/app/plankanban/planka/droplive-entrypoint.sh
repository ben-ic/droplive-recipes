#!/bin/sh
# Start Planka, then give it the company's four boards.
#
# Everything the seed does, it does through Planka's own API, as the person who
# actually did it: Planka takes the author of a card or a comment from the token
# rather than from the body, so the runner signs in as each of them in turn. The
# one thing the API cannot say is when a card or a comment was written, and a
# board whose every comment is a few seconds old is the one thing a worked-in
# board never looks like, so those two columns are corrected afterwards through
# the connection Planka itself is configured with.
#
# The seed is safe to re-run in the sense that matters: a second run would make
# a second copy, so it does not run at all if the boards are already there.
set -eu

SEED=/usr/local/lib/droplive-planka-seed.jsonl
RUNNER=/usr/local/lib/droplive-planka-seed.js

seed() {
  [ -r "$SEED" ] || return 0
  DROPLIVE_PLANKA_BASE="http://127.0.0.1:${PORT:-1337}" \
  DROPLIVE_PLANKA_SEED="$SEED" \
    node "$RUNNER" || echo "[droplive] seed failed; the app is still running" >&2
}

"$@" &
server_pid=$!
trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT

seed

wait "$server_pid"
