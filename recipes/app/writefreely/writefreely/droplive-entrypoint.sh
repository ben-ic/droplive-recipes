#!/bin/sh
set -eu

: "${APP_URL:?DropLive supplies the public application URL}"
: "${WRITEFREELY_ADMIN_PASSWORD:?DropLive supplies the administrator password}"
: "${WRITEFREELY_HASH_SEED:?DropLive supplies the server hash seed}"

data_dir=/writefreely
config="$data_dir/config.ini"
database="$data_dir/writefreely.db"
initialized="$data_dir/initialized"
writefreely=/go/cmd/writefreely/writefreely

mkdir -p "$data_dir"
fresh_database=false
if [ ! -f "$database" ]; then
  fresh_database=true
fi

if [ ! -f "$config" ]; then
  umask 077
  cat >"$config" <<EOF
[server]
port = 8080
bind = 0.0.0.0
templates_parent_dir = /go
static_parent_dir = /go
pages_parent_dir = /go
keys_parent_dir = /go
hash_seed = $WRITEFREELY_HASH_SEED

[database]
type = sqlite3
filename = $database

[app]
site_name = Northstar Relay
site_description = Company operating journal
host = $APP_URL
theme = write
single_user = true
open_registration = false
open_deletion = false
federation = false
public_stats = false
update_checks = false
EOF
fi

if [ ! -f "$initialized" ]; then
  if [ ! -f "$database" ]; then
    "$writefreely" -c "$config" db init
  fi
  "$writefreely" -c "$config" --create-admin "droplive:$WRITEFREELY_ADMIN_PASSWORD"
  touch "$initialized"
fi

if [ "$fresh_database" = true ]; then
  # WriteFreely's API is the supported path for publications. Seed only the
  # database this recipe just initialized, then leave later writing untouched.
  "$writefreely" -c "$config" serve &
  server_pid=$!
  cleanup() {
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  }
  trap cleanup EXIT HUP INT TERM

  token=""
  for _ in $(seq 1 60); do
    login=$(wget -qO- http://127.0.0.1:8080/api/auth/login \
      --post-data="{\"alias\":\"droplive\",\"pass\":\"$WRITEFREELY_ADMIN_PASSWORD\"}" \
      --header='Content-Type: application/json' || true)
    token=$(printf '%s' "$login" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
    [ -n "$token" ] && break
    sleep 1
  done

  if [ -z "$token" ]; then
    echo "WriteFreely owner login did not become ready for data seed" >&2
    exit 1
  fi

  publish() {
    wget -qO- http://127.0.0.1:8080/api/collections/droplive/posts \
      --post-data="$1" \
      --header='Content-Type: application/json' \
      --header="Authorization: Token $token" >/dev/null
  }

  publish '{"title":"Northstar Relay is live","body":"Northstar Relay is the operating journal for product direction, customer work, and release readiness.","font":"serif","language":"en"}'
  publish '{"title":"Release readiness","body":"This week the team reviews customer impact, support preparation, and the final rollout checklist.","font":"serif","language":"en"}'
  publish '{"title":"Customer notes","body":"The next operating review groups feedback by account, decision, owner, and follow-up date.","font":"serif","language":"en"}'

  unset WRITEFREELY_ADMIN_PASSWORD WRITEFREELY_HASH_SEED
  trap - EXIT HUP INT TERM
  wait "$server_pid"
  exit 0
fi

unset WRITEFREELY_ADMIN_PASSWORD WRITEFREELY_HASH_SEED
exec "$writefreely" -c "$config" serve
