#!/bin/sh
# Start Metabase, then give it the Northstar Relay company to report on.
#
# The seed runs THROUGH METABASE'S OWN API. Setup, the data source, every saved
# question, the dashboard and the home page are the endpoints the application's
# own screens call, and the analytics tables are created and filled through the
# native-query endpoint -- the SQL editor. That is not a shortcut around a nicer
# path: the image is a JRE and a jar, with no psql and no other database client,
# so the SQL editor is the only way in. The connection it uses is the one
# DropLive already handed the application.
#
# A statement that returns no rows makes Metabase report "did not produce a
# ResultSet" even though Postgres ran it, so every DDL batch in the seed opens
# with `SELECT 1 AS ok;` and every insert ends with RETURNING. A real failure
# still looks like a failure.
set -eu

SEED=/usr/local/lib/droplive-metabase-seed.requests
MAP=/tmp/droplive-metabase-bindings.sed
BODY=/tmp/droplive-metabase-response
BASE="http://127.0.0.1:${MB_JETTY_PORT:-3000}"

# The identifier a created object carries, read off the top level of the
# response. Metabase answers with nested objects that have `id` fields of their
# own -- the creator, the collection, the result metadata -- so matching the
# first or the last one in the text returns somebody else's number. This walks
# the response and keeps only what is at depth one.
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

# A value that later lines refer to by name. The quoted rule runs first so a
# binding used as a JSON value becomes a number, while the same name used inside
# a request path becomes bare text.
bind() {
  printf 's|"@%s@"|%s|g\ns|@%s@|%s|g\n' "$1" "$2" "$1" "$2" >>"$MAP"
}

# A binding that is a string wherever it appears, so the quotes around it stay.
bind_text() {
  printf 's|@%s@|%s|g\n' "$1" "$(printf '%s' "$2" | sed 's/[\\&|]/\\&/g')" >>"$MAP"
}

seed() {
  # No minted password means no account to hand the visitor, so the demo is left
  # on Metabase's own first-run screen rather than half-configured.
  password="${METABASE_OWNER_PASSWORD:-}"
  [ -n "$password" ] || { echo "[droplive] no owner password; leaving Metabase unseeded" >&2; return 0; }
  [ -r "$SEED" ] || return 0

  waited=0
  while [ "$waited" -lt 300 ]; do
    if curl -s -m 5 "$BASE/api/health" 2>/dev/null | grep -q '"status":"ok"'; then break; fi
    sleep 2
    waited=$((waited + 2))
  done
  [ "$waited" -lt 300 ] || { echo "[droplive] metabase did not become ready; skipping seed" >&2; return 0; }

  # IDEMPOTENT BY THE FACT METABASE ITSELF KEEPS: whether anybody has completed
  # first-run setup. The setup token is issued once and is refused afterwards, so
  # a restart cannot create a second company.
  properties=$(curl -s -m 20 "$BASE/api/session/properties" 2>/dev/null || true)
  case "$properties" in
  *'"has-user-setup":true'*)
    echo "[droplive] metabase is already set up; leaving the reports alone" >&2
    return 0
    ;;
  esac

  token=$(printf '%s' "$properties" | sed -n 's/.*"setup-token":"\([^"]*\)".*/\1/p')
  [ -n "$token" ] || { echo "[droplive] metabase issued no setup token; skipping seed" >&2; return 0; }

  # Maya is the account on the sign-in card. Metabase requires a digit in a
  # password, which is why the recipe constrains the value it mints.
  session=$(printf '{"token":"%s","user":{"first_name":"Maya","last_name":"Chen","email":"maya@northstar-relay.droplive.test","password":"%s","site_name":"Northstar Relay"},"prefs":{"site_name":"Northstar Relay","site_locale":"en","allow_tracking":false}}' "$token" "$password" |
    curl -s -m 60 -H 'Content-Type: application/json' --data-binary @- "$BASE/api/setup" 2>/dev/null |
    sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
  [ -n "$session" ] || { echo "[droplive] metabase setup was refused; skipping seed" >&2; return 0; }

  # The data source the reports read is the demo's own database, which the
  # application was already given. The seed never invents a connection.
  : >"$MAP"
  bind_text "companion:host" "${MB_DB_HOST:-127.0.0.1}"
  bind_text "companion:port" "${MB_DB_PORT:-5432}"
  bind_text "companion:database" "${MB_DB_DBNAME:-metabase}"
  bind_text "companion:username" "${MB_DB_USER:-metabase}"
  bind_text "companion:password" "${MB_DB_PASS:-}"

  written=0
  failed=0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    line=$(printf '%s' "$line" | sed -f "$MAP")
    verb=${line%% *}
    rest=${line#* }
    path=${rest%% *}
    rest=${rest#* }
    name=${rest%% *}
    payload=${rest#* }

    code=$(printf '%s' "$payload" | curl -s -m 300 -o "$BODY" -w '%{http_code}' \
      -X "$verb" -H "X-Metabase-Session: $session" -H 'Content-Type: application/json' \
      --data-binary @- "$BASE$path" 2>/dev/null || echo 000)

    # A native query answers 202 whether it ran or not, so its own status decides.
    ok=0
    case "$code" in
    2*) ok=1 ;;
    esac
    case "$path" in
    /api/dataset)
      ok=0
      grep -q '"status":"completed"' "$BODY" 2>/dev/null && ok=1
      ;;
    esac

    if [ "$ok" = 0 ]; then
      failed=$((failed + 1))
      echo "[droplive] metabase refused $verb $path ($code): $(head -c 200 "$BODY" 2>/dev/null)" >&2
      continue
    fi
    written=$((written + 1))

    if [ "$name" != "-" ]; then
      value=$(json_id "$BODY")
      if [ -n "$value" ]; then
        bind "$name" "$value"
      else
        echo "[droplive] metabase returned no identifier for $name" >&2
      fi
    fi
  done <"$SEED"

  rm -f "$MAP" "$BODY"
  echo "[droplive] seeded metabase with $written requests, $failed refused" >&2
}

"$@" &
server_pid=$!
trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT

seed || echo "[droplive] seed failed; the app is still running" >&2

wait "$server_pid"
