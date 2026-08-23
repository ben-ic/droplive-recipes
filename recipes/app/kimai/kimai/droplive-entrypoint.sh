#!/bin/bash
# Start Kimai, then give it the Northstar Relay company to keep time for.
#
# The seed runs THROUGH KIMAI'S OWN REST API. Customers, projects, activities,
# tags, users and every timesheet are created by documented endpoints, so the
# demo exercises the path an operator or an integration uses and nothing here
# depends on a private schema.
#
# Kimai's API token can only be minted from a signed-in profile page, and the
# console has no command for one. The API accepts a signed-in session as well, so
# the seeder signs in the way a person does -- the login form, with the password
# DropLive minted -- and uses that. The same session answers the first-run wizard,
# which is otherwise the first thing a visitor sees and the last thing a demo
# should ask them to fill in.
set -euo pipefail

SEED=/usr/local/lib/droplive-kimai-seed.requests
MAP=/tmp/droplive-kimai-bindings.sed
BODY=/tmp/droplive-kimai-response
JAR=/tmp/droplive-kimai-cookies
BASE=http://127.0.0.1:8001

# The identifier a created object carries, read off the top level of the
# response. Kimai answers with nested objects that have `id` fields of their own,
# so matching the first or the last one in the text returns somebody else's
# number. This walks the response and keeps only what is at depth one.
json_id() {
  awk '
  { line = line $0 }
  END {
    depth = 0; instr = 0; esc = 0; flat = ""
    n = length(line)
    for (i = 1; i <= n; i++) {
      c = substr(line, i, 1)
      if (instr) {
        if (esc) esc = 0
        else if (c == "\\") esc = 1
        else if (c == "\"") instr = 0
        if (depth <= 1) flat = flat c
        continue
      }
      if (c == "\"") { instr = 1; if (depth <= 1) flat = flat c; continue }
      if (c == "{" || c == "[") { depth++; if (depth <= 1) flat = flat c; continue }
      if (c == "}" || c == "]") { if (depth <= 1) flat = flat c; depth--; continue }
      if (depth <= 1) flat = flat c
    }
    if (match(flat, "\"id\":[0-9]+")) {
      v = substr(flat, RSTART, RLENGTH); sub(/^"id":/, "", v); print v
    }
  }' "$1"
}

# A value later lines refer to by name. The quoted rule runs first so a binding
# used as a JSON value becomes a number, while the same name used inside a
# request path becomes bare text.
bind() {
  printf 's|"@%s@"|%s|g\ns|@%s@|%s|g\n' "$1" "$2" "$1" "$2" >>"$MAP"
}

# The hidden field Symfony requires before it will accept a form.
csrf_token() {
  sed -n 's/.*name="'"$2"'"[^>]*value="\([^"]*\)".*/\1/p' "$1" | head -1
}

seed() {
  password="${ADMINPASS:-}"
  [[ -n "$password" ]] || { echo "[droplive] no owner password; leaving Kimai unseeded" >&2; return 0; }
  [[ -r "$SEED" ]] || return 0

  # Ready, not merely listening: Kimai runs its migrations and warms its cache
  # during startup and only redirects to the sign-in page once it has.
  waited=0
  while [[ "$waited" -lt 300 ]]; do
    code=$(curl -s -o /dev/null -m 5 -w '%{http_code}' "$BASE/" 2>/dev/null || echo 000)
    [[ "$code" == "302" || "$code" == "200" ]] && break
    sleep 2
    waited=$((waited + 2))
  done
  [[ "$waited" -lt 300 ]] || { echo "[droplive] kimai did not become ready; skipping seed" >&2; return 0; }

  rm -f "$JAR"
  curl -s -m 30 -L -c "$JAR" -o "$BODY" "$BASE/" 2>/dev/null || true
  token=$(csrf_token "$BODY" _csrf_token)
  [[ -n "$token" ]] || { echo "[droplive] kimai showed no sign-in form; skipping seed" >&2; return 0; }

  curl -s -m 30 -o /dev/null -b "$JAR" -c "$JAR" \
    --data-urlencode "_csrf_token=$token" \
    --data-urlencode "_username=${ADMINMAIL:-}" \
    --data-urlencode "_password=$password" \
    "$BASE/en/login_check" 2>/dev/null || true

  if ! curl -s -m 30 -b "$JAR" -o "$BODY" "$BASE/api/users/me" 2>/dev/null || ! grep -q '"username"' "$BODY"; then
    echo "[droplive] kimai refused the owner sign-in; skipping seed" >&2
    return 0
  fi
  owner=$(json_id "$BODY")

  # Kimai opens on a first-run wizard until somebody answers it, which is a setup
  # screen where the demo should have been. The wizard is a sequence: some steps
  # are a form and some are a page with a next link, and the home page is what
  # decides which one is due. Answering them here is the same walk a person does,
  # with the values the recipe already chose.
  for _ in 1 2 3 4 5; do
    landed=$(curl -s -m 30 -L -b "$JAR" -c "$JAR" -o "$BODY" -w '%{url_effective}' \
      "$BASE/en/homepage" 2>/dev/null || true)
    case "$landed" in
    */wizard/*) ;;
    *) break ;;
    esac
    wizard=$(csrf_token "$BODY" 'form\[_token\]')
    if [[ -n "$wizard" ]]; then
      curl -s -m 30 -o /dev/null -b "$JAR" -c "$JAR" \
        --data-urlencode "form[_token]=$wizard" \
        --data-urlencode "form[language]=en" \
        --data-urlencode "form[locale]=en" \
        --data-urlencode "form[timezone]=Europe/London" \
        --data-urlencode "form[skin]=default" \
        "$landed" 2>/dev/null || true
    else
      curl -s -m 30 -o /dev/null -L -b "$JAR" -c "$JAR" "$BASE/en/wizard/next/" 2>/dev/null || true
    fi
  done
  case "$landed" in
  */wizard/*) echo "[droplive] kimai still wants its first-run wizard answered" >&2 ;;
  esac

  # IDEMPOTENT ON THE FIRST THING THE SEED CREATES. Kimai's own customer list
  # settles it: if Northstar's accounts are there, this database has been seeded
  # and a restart must leave it alone rather than doubling four hundred entries.
  curl -s -m 30 -b "$JAR" -o "$BODY" "$BASE/api/customers" 2>/dev/null || true
  if grep -q '"name":"Lumen Labs"' "$BODY"; then
    echo "[droplive] kimai already has the Northstar accounts; leaving them alone" >&2
    return 0
  fi

  : >"$MAP"
  bind "user:maya" "$owner"

  written=0
  failed=0
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    # Every identifier this line depends on was bound by an earlier line, and each
    # of the nine accounts nobody signs in as gets its own throwaway secret.
    line=$(printf '%s' "$line" | sed -f "$MAP" | sed "s|@secret:random@|$(openssl rand -hex 24)|g")
    verb=${line%% *}
    rest=${line#* }
    path=${rest%% *}
    rest=${rest#* }
    name=${rest%% *}
    payload=${rest#* }

    code=$(printf '%s' "$payload" | curl -s -m 60 -o "$BODY" -w '%{http_code}' \
      -X "$verb" -b "$JAR" -H 'Content-Type: application/json' \
      --data-binary @- "$BASE$path" 2>/dev/null || echo 000)

    case "$code" in
    2*) ;;
    *)
      failed=$((failed + 1))
      echo "[droplive] kimai refused $verb $path ($code): $(head -c 200 "$BODY" 2>/dev/null)" >&2
      continue
      ;;
    esac
    written=$((written + 1))

    if [[ "$name" != "-" ]]; then
      value=$(json_id "$BODY")
      if [[ -n "$value" ]]; then
        bind "$name" "$value"
      else
        echo "[droplive] kimai returned no identifier for $name" >&2
      fi
    fi
  done <"$SEED"

  rm -f "$MAP" "$BODY" "$JAR"
  echo "[droplive] seeded kimai with $written requests, $failed refused" >&2
}

# Kimai's own entrypoint runs `kimai:install` before it starts Apache, and that
# command waits for the database in a loop that prints nothing. If the companion
# is not accepting connections yet, the whole start sits in that loop until the
# readiness probe gives up, and what the build log shows is a php process and a
# `sleep 2` -- which reads as a slow install rather than as a missing database.
# So the wait happens here instead, where it can say what it is waiting for and
# give up out loud.
wait_for_database() {
  [ -n "${DATABASE_URL:-}" ] || return 0

  # host:port out of scheme://user:pass@host:port/name?options, without needing
  # a URL parser. The scheme goes first, then everything through the LAST @ --
  # the last, because a generated password may contain one and the first @ would
  # then leave half of it in the hostname.
  rest=${DATABASE_URL#*://}
  rest=${rest##*@}
  hostport=${rest%%/*}
  hostport=${hostport%%\?*}
  host=${hostport%%:*}
  port=${hostport##*:}
  if [ "$port" = "$host" ]; then port=3306; fi
  [ -n "$host" ] || return 0

  waited=0
  while [ "$waited" -lt 120 ]; do
    if (exec 3<>"/dev/tcp/$host/$port") 2>/dev/null; then
      if [ "$waited" -gt 0 ]; then
        echo "[droplive] database answered after ${waited}s" >&2
      fi
      return 0
    fi
    sleep 1
    waited=$((waited + 1))
  done

  echo "[droplive] no database at $host:$port after ${waited}s; starting anyway" >&2
}

wait_for_database

"$@" &
server_pid=$!
trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT

seed || echo "[droplive] seed failed; the app is still running" >&2

wait "$server_pid"
