#!/bin/sh
set -eu

# Listmonk uses mixed-case configuration names. DropLive binds portable
# upper-case names, so map the reviewed companion values at the recipe edge.
export LISTMONK_db__host="${LISTMONK_DB_HOST:?missing database host}"
export LISTMONK_db__port="${LISTMONK_DB_PORT:?missing database port}"
export LISTMONK_db__database="${LISTMONK_DB_DATABASE:?missing database name}"
export LISTMONK_db__user="${LISTMONK_DB_USER:?missing database user}"
export LISTMONK_db__password="${LISTMONK_DB_PASSWORD:?missing database password}"

./listmonk --install --idempotent --yes --config ''
./listmonk --upgrade --yes --config ''

SEED=/usr/local/lib/droplive-listmonk-seed.requests
MAP=/tmp/droplive-listmonk-bindings.sed
BODY=/tmp/droplive-listmonk-response
BASE=http://127.0.0.1:9000

# Listmonk answers {"data":{"id":N,...}}, so the identifier is one level inside
# the envelope rather than at the top of the response.
json_id() {
  sed -n 's/^{"data":{"id":\([0-9][0-9]*\).*/\1/p' "$1" | head -1
}

bind() {
  printf 's|"@%s@"|%s|g\n' "$1" "$2" >>"$MAP"
}

# Only what application/x-www-form-urlencoded actually reserves. A generated
# password contains & and %, and either of them unencoded silently signs in as
# somebody with a shorter password.
form_encode() {
  printf '%s' "$1" | sed -e 's/%/%25/g' -e 's/&/%26/g' -e 's/+/%2B/g' -e 's/=/%3D/g'
}

# EVERY request is spoken directly over a socket, because BusyBox wget cannot do
# any of the three things this needs: it has no cookie jar, it does not report
# Set-Cookie, and it has no way to send a DELETE. nc plus HTTP/1.0 does all three.
#
# HTTP/1.0 on purpose. A 1.1 server is free to answer with chunked transfer
# encoding, and unchunking a body in shell is a parser nobody should write; a 1.0
# request gets a plain body terminated by the close.
request() {
  _method=$1
  _path=$2
  _payload=$3
  _length=$(printf '%s' "$_payload" | wc -c | tr -d ' ')
  {
    printf '%s %s HTTP/1.0\r\n' "$_method" "$_path"
    printf 'Host: 127.0.0.1:9000\r\n'
    printf 'Content-Type: application/json\r\n'
    [ -n "${cookie:-}" ] && printf 'Cookie: session=%s\r\n' "$cookie"
    printf 'Content-Length: %s\r\n\r\n' "$_length"
    printf '%s' "$_payload"
  } | nc 127.0.0.1 9000 2>/dev/null
}

# The response body: everything after the blank line that ends the headers.
body_of() {
  sed -n '/^\r\{0,1\}$/,$p' | sed '1d'
}

status_of() {
  head -1 | sed -n 's|^HTTP/[0-9.]* \([0-9][0-9][0-9]\).*|\1|p'
}

login() {
  _body="username=$(form_encode "${LISTMONK_ADMIN_USER:-admin}")&password=$(form_encode "$1")"
  {
    printf 'POST /admin/login HTTP/1.0\r\n'
    printf 'Host: 127.0.0.1:9000\r\n'
    printf 'Content-Type: application/x-www-form-urlencoded\r\n'
    printf 'Content-Length: %s\r\n\r\n' "$(printf '%s' "$_body" | wc -c | tr -d ' ')"
    printf '%s' "$_body"
  } | nc 127.0.0.1 9000 2>/dev/null |
    sed -n 's/.*[Ss]et-[Cc]ookie: *session=\([^;]*\).*/\1/p' | head -1 | tr -d '\r'
}

seed() {
  password="${LISTMONK_ADMIN_PASSWORD:-}"
  [ -n "$password" ] || { echo "[droplive] no owner password; leaving Listmonk unseeded" >&2; return 0; }
  [ -r "$SEED" ] || return 0

  waited=0
  while [ "$waited" -lt 120 ]; do
    if wget -q -T 3 -O /dev/null "$BASE/health" 2>/dev/null; then break; fi
    sleep 1
    waited=$((waited + 1))
  done
  [ "$waited" -lt 120 ] || { echo "[droplive] listmonk did not become ready; skipping seed" >&2; return 0; }

  # Version 6 refuses HTTP basic auth from a dashboard account -- that path is for
  # API users with tokens, and there is no command to mint one -- but it accepts a
  # signed-in session, so the seeder signs in the way a person does.
  session=$(login "$password")
  [ -n "$session" ] || { echo "[droplive] listmonk refused the owner sign-in; skipping seed" >&2; return 0; }
  cookie=$session

  # IDEMPOTENT ON LISTMONK'S OWN LISTS. If Northstar's are there this database has
  # been seeded, and a restart must not add a second copy of every subscriber.
  request GET /api/lists "" | body_of >"$BODY"
  if grep -q '"name":"Customers"' "$BODY" 2>/dev/null; then
    echo "[droplive] listmonk already has the Northstar lists; leaving them alone" >&2
    return 0
  fi

  : >"$MAP"
  written=0
  failed=0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    line=$(printf '%s' "$line" | sed -f "$MAP")
    method=${line%% *}
    rest=${line#* }
    path=${rest%% *}
    rest=${rest#* }
    name=${rest%% *}
    payload=${rest#* }

    request "$method" "$path" "$payload" >"$BODY".raw
    code=$(status_of <"$BODY".raw)
    body_of <"$BODY".raw >"$BODY"

    case "$code" in
    2*)
      written=$((written + 1))
      if [ "$name" != "-" ]; then
        value=$(json_id "$BODY")
        [ -n "$value" ] && bind "$name" "$value"
      fi
      ;;
    *)
      failed=$((failed + 1))
      echo "[droplive] listmonk answered $code to $method $path" >&2
      ;;
    esac
  done <"$SEED"

  rm -f "$MAP" "$BODY" "$BODY".raw
  echo "[droplive] seeded listmonk with $written requests, $failed refused" >&2
}

./listmonk --config '' &
server_pid=$!
trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT

seed || echo "[droplive] seed failed; the app is still running" >&2

wait "$server_pid"
