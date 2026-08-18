#!/bin/sh
set -eu

# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=LUBELOGGER_BOOTSTRAP_PASSWORD capability=owner-login username=admin
: "${LUBELOGGER_BOOTSTRAP_PASSWORD:?DropLive must generate the initial owner password}"

password_length=${#LUBELOGGER_BOOTSTRAP_PASSWORD}
password_charset=url-safe
test -z "$(printf '%s' "$LUBELOGGER_BOOTSTRAP_PASSWORD" | LC_ALL=C tr -d 'A-Za-z0-9_-')" || password_charset=other
if [ "$password_length" -ne 16 ] || [ "$password_charset" != url-safe ]; then
  echo "LUBELOGGER_BOOTSTRAP_PASSWORD must contain exactly 16 URL-safe characters" >&2
  exit 1
fi
unset password_length password_charset

umask 077
mkdir -p /App/data/config

config=/App/data/config/userConfig.json
if [ ! -e "${config}" ]; then
  username_hash=$(printf '%s' admin | sha256sum | awk '{print $1}')
  password_hash=$(printf '%s' "${LUBELOGGER_BOOTSTRAP_PASSWORD}" | sha256sum | awk '{print $1}')
  temporary="${config}.tmp.$$"
  printf '{"EnableAuth":true,"UserNameHash":"%s","UserPasswordHash":"%s"}\n' \
    "${username_hash}" "${password_hash}" >"${temporary}"
  mv "${temporary}" "${config}"
fi

# The persisted hashes, not the plaintext bootstrap password, are inherited by
# the application. The owner can rotate credentials through LubeLogger later.
unset LUBELOGGER_BOOTSTRAP_PASSWORD
exec "$@"
