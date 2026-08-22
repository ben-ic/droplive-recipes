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
site_name = DropLive WriteFreely
site_description = A private writing demo
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

unset WRITEFREELY_ADMIN_PASSWORD WRITEFREELY_HASH_SEED
exec "$writefreely" -c "$config" serve
