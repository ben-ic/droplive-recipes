#!/bin/sh
# Start Gogs, answer its install form, then give it the Northstar repositories.
#
# Gogs ships unconfigured and serves its install wizard until somebody fills the
# form in, so the demo opened on a setup screen asking a visitor to choose a
# database. This answers that form -- the same POST the wizard makes -- which is
# also what creates the owner account.
#
# The `admin create-user` command would be the obvious way to make that account
# without the form. It does not work: on an empty database 0.14.3 answers
# "create user: user already exists" for any name at all, before any user exists.
#
# The repositories and their issues are then created THROUGH GOGS' OWN API.
set -eu

# droplive: generate=hex64 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=APP_ADMIN_PASSWORD capability=owner-login username=maya
: "${APP_ADMIN_PASSWORD:?DropLive must generate the initial owner password}"

SEED=/usr/local/lib/droplive-gogs-seed.requests
JAR=/tmp/droplive-gogs-cookies
BASE=http://127.0.0.1:3000
OWNER=maya
OWNER_EMAIL=maya@northstar-relay.invalid

if [ "${#APP_ADMIN_PASSWORD}" -lt 12 ]; then
  echo "APP_ADMIN_PASSWORD must contain at least 12 characters" >&2
  exit 64
fi

install_gogs() {
  csrf=$(curl -s -m 20 -c "$JAR" "$BASE/install" 2>/dev/null |
    sed -n 's/.*name="_csrf" value="\([^"]*\)".*/\1/p' | head -1)
  curl -s -o /dev/null -m 60 -b "$JAR" -c "$JAR" \
    --data-urlencode "_csrf=$csrf" \
    --data-urlencode "db_type=SQLite3" \
    --data-urlencode "db_host=127.0.0.1:3306" \
    --data-urlencode "db_user=gogs" \
    --data-urlencode "db_passwd=" \
    --data-urlencode "db_name=gogs" \
    --data-urlencode "ssl_mode=disable" \
    --data-urlencode "db_path=/data/gogs.db" \
    --data-urlencode "app_name=Northstar Relay" \
    --data-urlencode "repo_root_path=/data/git/gogs-repositories" \
    --data-urlencode "run_user=git" \
    --data-urlencode "domain=localhost" \
    --data-urlencode "ssh_port=22" \
    --data-urlencode "http_port=3000" \
    --data-urlencode "app_url=${APP_BASE_URL:-http://localhost:3000/}" \
    --data-urlencode "log_root_path=/app/gogs/log" \
    --data-urlencode "default_branch=main" \
    --data-urlencode "disable_registration=on" \
    --data-urlencode "offline_mode=on" \
    --data-urlencode "admin_name=$OWNER" \
    --data-urlencode "admin_passwd=$APP_ADMIN_PASSWORD" \
    --data-urlencode "admin_confirm_passwd=$APP_ADMIN_PASSWORD" \
    --data-urlencode "admin_email=$OWNER_EMAIL" \
    "$BASE/install" 2>/dev/null || true
}

seed() {
  [ -r "$SEED" ] || return 0

  # Ready enough to be installed: the wizard answers before anything else does.
  waited=0
  while [ "$waited" -lt 180 ]; do
    if curl -s -o /dev/null -m 3 "$BASE/" 2>/dev/null; then break; fi
    sleep 1
    waited=$((waited + 1))
  done
  [ "$waited" -lt 180 ] || { echo "[droplive] gogs did not become ready; skipping seed" >&2; return 0; }

  # IDEMPOTENT ON GOGS' OWN INSTALL STATE. /install answers 200 only while the
  # wizard is still waiting; once it is done Gogs redirects away from it, and a
  # restart neither reinstalls nor creates a second owner.
  if [ "$(curl -s -o /dev/null -m 10 -w '%{http_code}' "$BASE/install" 2>/dev/null)" = "200" ]; then
    install_gogs
    sleep 3
  else
    echo "[droplive] gogs is already installed; leaving it alone" >&2
    return 0
  fi

  # Gogs accepts the owner's own credentials on exactly one endpoint: the one that
  # mints a token. Everything else in the API wants the token.
  token=$(printf '{"name":"droplive-seed"}' |
    curl -s -m 30 -u "$OWNER:$APP_ADMIN_PASSWORD" -H 'Content-Type: application/json' \
      --data-binary @- "$BASE/api/v1/users/$OWNER/tokens" 2>/dev/null |
    sed -n 's/.*"sha1": *"\([^"]*\)".*/\1/p')
  [ -n "$token" ] || { echo "[droplive] gogs would not mint an API token; skipping seed" >&2; return 0; }

  written=0
  failed=0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    method=${line%% *}
    rest=${line#* }
    path=${rest%% *}
    rest=${rest#* }
    payload=${rest#* }

    code=$(printf '%s' "$payload" | curl -s -o /dev/null -w '%{http_code}' -m 60 \
      -X "$method" -H "Authorization: token $token" -H 'Content-Type: application/json' \
      --data-binary @- "$BASE$path" 2>/dev/null || echo 000)
    case "$code" in
    2*) written=$((written + 1)) ;;
    *)
      failed=$((failed + 1))
      echo "[droplive] gogs answered $code to $method $path" >&2
      ;;
    esac
  done <"$SEED"
  rm -f "$JAR"
  echo "[droplive] seeded gogs with $written requests, $failed refused" >&2
}

"$@" &
server_pid=$!
trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT

seed || echo "[droplive] seed failed; the app is still running" >&2

wait "$server_pid"
