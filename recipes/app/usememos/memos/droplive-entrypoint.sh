#!/bin/sh
# Start Memos, then fill it with the shared Northstar notebook.
#
# The seed runs THROUGH THE PUBLIC API, not against the SQLite file. Memos' own
# HTTP API creates the first user and every memo, so the demo exercises the same
# path a real operator would and nothing here depends on a private schema.
#
# BusyBox wget is the only HTTP client in this image and it speaks GET and POST.
# That is enough: every seed call is a POST. It is also why no memo is pinned --
# pinning is a PATCH, and ordering the summary newest puts it at the top of the
# timeline for free.
set -eu

seed() {
  # No password means no owner to create, so there is nothing to seed and the app
  # comes up on its own setup screen rather than half-configured.
  password="${MEMOS_OWNER_PASSWORD:-}"
  [ -n "$password" ] || return 0
  [ -r /usr/local/lib/droplive-memos-seed.jsonl ] || return 0

  base="http://127.0.0.1:${MEMOS_PORT:-5230}"

  # Ready, not merely listening: the API answers 401 before it answers anything
  # useful, and a create sent into that window is lost with no error a visitor
  # would ever see.
  waited=0
  while [ "$waited" -lt 90 ]; do
    if wget -q -T 3 -O /dev/null "$base/healthz" 2>/dev/null; then break; fi
    sleep 1
    waited=$((waited + 1))
  done
  [ "$waited" -lt 90 ] || { echo "[droplive] memos did not become ready; skipping seed" >&2; return 0; }

  # IDEMPOTENT BY THE ONLY FACT THAT SETTLES IT: whether an owner already exists.
  # Creating the first user is unauthenticated and open exactly once; after that
  # this POST fails, and that failure is the signal that this session's volume was
  # already seeded. Restarting must not double the notebook.
  if ! wget -q -T 10 -O /dev/null \
      --header 'content-type: application/json' \
      --post-data "{\"username\":\"maya\",\"password\":\"$password\",\"role\":\"HOST\"}" \
      "$base/api/v1/users" 2>/dev/null; then
    echo "[droplive] memos already has an owner; leaving the notebook alone" >&2
    return 0
  fi

  token=$(wget -q -T 10 -O - \
    --header 'content-type: application/json' \
    --post-data "{\"passwordCredentials\":{\"username\":\"maya\",\"password\":\"$password\"}}" \
    "$base/api/v1/auth/signin" 2>/dev/null |
    sed -n 's/.*"accessToken":[[:space:]]*"\([^"]*\)".*/\1/p')
  [ -n "$token" ] || { echo "[droplive] memos sign-in produced no token; skipping seed" >&2; return 0; }

  # One complete request body per line, so the shell never has to quote or escape
  # markdown. The file is written by the recipe, from the pinned world.
  written=0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    if wget -q -T 10 -O /dev/null \
        --header 'content-type: application/json' \
        --header "authorization: Bearer $token" \
        --post-data "$line" \
        "$base/api/v1/memos" 2>/dev/null; then
      written=$((written + 1))
    else
      echo "[droplive] a memo failed to write" >&2
    fi
  done < /usr/local/lib/droplive-memos-seed.jsonl
  echo "[droplive] seeded $written memos" >&2
}

"$@" &
server_pid=$!
trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT

seed || echo "[droplive] seed failed; the app is still running" >&2

# The notebook was full when the visitor arrived; the world says a few more
# things happen after they get here. This runs in the background because it
# spends most of its life asleep, and it exits after the last one rather than
# waiting for something that will not come.
if [ -x /usr/local/lib/droplive-memos-arrivals.sh ]; then
  /usr/local/lib/droplive-memos-arrivals.sh &
fi

wait "$server_pid"
