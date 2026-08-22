#!/bin/sh
# droplive: generate=hex64 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=NODE_RED_ADMIN_PASSWORD capability=owner-login username=admin
set -eu

if test "$(id -u)" = 0; then
  mkdir -p /data
  chown node-red:root /data
  chmod 0770 /data
  exec su node-red -c 'exec /usr/src/node-red/droplive-entrypoint.sh --drop-privileges-complete'
fi

if test "${1:-}" != --drop-privileges-complete; then
  echo '[node-red-init] Refusing to initialize without the bounded privilege-drop step.' >&2
  exit 64
fi

: "${NODE_RED_ADMIN_PASSWORD:?DropLive must generate NODE_RED_ADMIN_PASSWORD}"
# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=NODE_RED_CREDENTIAL_SECRET
: "${NODE_RED_CREDENTIAL_SECRET:?DropLive must generate NODE_RED_CREDENTIAL_SECRET}"

validate_lowerhex_64() {
  variable_name=$1
  eval "variable_value=\${$variable_name}"
  variable_length=${#variable_value}
  variable_charset=lowerhex
  test -z "$(printf '%s' "$variable_value" | tr -d '0-9a-f')" || variable_charset=other
  if test "$variable_length" -lt 64 || test "$variable_charset" != lowerhex; then
    echo "[node-red-init] $variable_name shape rejected: observed_length=$variable_length observed_charset=$variable_charset required=64-or-more-lowerhex." >&2
    exit 64
  fi
  unset variable_name variable_value variable_length variable_charset
}

validate_human_password_16() {
  variable_name=$1
  eval "variable_value=\${$variable_name}"
  variable_length=${#variable_value}
  variable_charset=url-safe
  test -z "$(printf '%s' "$variable_value" | LC_ALL=C tr -d 'A-Za-z0-9_-')" || variable_charset=other
  if test "$variable_length" -lt 16 || test "$variable_charset" != url-safe; then
    echo "[node-red-init] $variable_name shape rejected: observed_length=$variable_length observed_charset=$variable_charset required=16-or-more-url-safe." >&2
    exit 64
  fi
  unset variable_name variable_value variable_length variable_charset
}

validate_human_password_16 NODE_RED_ADMIN_PASSWORD
validate_lowerhex_64 NODE_RED_CREDENTIAL_SECRET

umask 077

if test ! -s /data/.droplive-credential-secret; then
  printf '%s\n' "$NODE_RED_CREDENTIAL_SECRET" > /data/.droplive-credential-secret
fi
unset NODE_RED_CREDENTIAL_SECRET

# Read the generated administrator password only from stdin inside the bounded
# hashing child. The raw password is never written to disk or passed in argv.
admin_hash=$(
  printf '%s\n' "$NODE_RED_ADMIN_PASSWORD" | \
    timeout -s TERM 30 node -e \
      "const fs=require('fs'); const bcrypt=require('bcryptjs'); const value=fs.readFileSync(0,'utf8').trimEnd(); process.stdout.write(bcrypt.hashSync(value,8));"
)
unset NODE_RED_ADMIN_PASSWORD
printf '%s\n' "$admin_hash" > /data/.droplive-admin-password-hash
unset admin_hash

if test ! -e /data/settings.js; then
  cp /usr/src/node-red/droplive-settings.js /data/settings.js
fi
if test ! -e /data/flows.json; then
  cp /usr/src/node-red/droplive-flows.json /data/flows.json
fi

echo '[node-red-runtime] Starting Node-RED on port 1880 as UID 1000.'
cd /usr/src/node-red
exec ./entrypoint.sh
