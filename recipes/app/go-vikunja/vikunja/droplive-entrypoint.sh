#!/bin/sh
set -eu

# Use the platform's canonical generated names, then map them to Vikunja. This
# keeps the recipe generic and makes the owner password directly revealable.
# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=SECRET_KEY_BASE
# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=APP_ADMIN_PASSWORD capability=owner-login username=maya
: "${SECRET_KEY_BASE:?DropLive must generate SECRET_KEY_BASE}"
: "${APP_ADMIN_PASSWORD:?DropLive must generate APP_ADMIN_PASSWORD}"
: "${APP_BASE_URL:?DropLive must derive APP_BASE_URL from the public origin}"

validate_human_password_16() {
  value=$1
  name=$2
  if test "${#value}" -lt 16; then
    echo "$name must contain at least 16 URL-safe characters" >&2
    exit 64
  fi
  case "$value" in
    *[!A-Za-z0-9_-]*)
      echo "$name must contain at least 16 URL-safe characters" >&2
      exit 64
      ;;
  esac
}

if test "${#SECRET_KEY_BASE}" -lt 32; then
  echo "SECRET_KEY_BASE must contain at least 32 cryptographically random characters" >&2
  exit 64
fi
validate_human_password_16 "$APP_ADMIN_PASSWORD" APP_ADMIN_PASSWORD

case "$APP_BASE_URL" in
  https://*) ;;
  *)
    echo "APP_BASE_URL must be the assigned public HTTPS origin" >&2
    exit 64
    ;;
esac

test -d /data
test -w /data
/bin/mkdir -p /data/files
test -d /data/files
test -w /data/files
test -d /tmp
test -w /tmp

export VIKUNJA_SERVICE_PUBLICURL="${APP_BASE_URL%/}/"
export VIKUNJA_SERVICE_SECRET="$SECRET_KEY_BASE"

owner_check=/tmp/droplive-vikunja-owner.$$.txt
owner_username=maya
owner_email=maya@northstar-relay.droplive.test
seeded=/app/droplive-vikunja.db
cleanup() {
  rm -f "$owner_check"
}
trap cleanup EXIT HUP INT TERM
umask 077

verify_owner() {
  rm -f "$owner_check"
  /app/vikunja/vikunja user list --email "$owner_email" >"$owner_check" 2>&1
  grep -F "$owner_username" "$owner_check" >/dev/null
  grep -F "$owner_email" "$owner_check" >/dev/null
}

# The company's boards were built into a database when the image was built.
# The first start puts that database in place; every start after this one finds
# it already there and leaves whatever the visitor has done to it alone.
if ! test -s /data/vikunja.db; then
  test -s "$seeded"
  cp "$seeded" /data/vikunja.db
fi

verify_owner || {
  echo "the Vikunja database has no Northstar owner; refusing unsafe bootstrap" >&2
  exit 65
}

# The seeded database carries a build-time password that authenticates nothing.
# The account is handed the value DropLive minted for this session, before the
# app is reachable. Vikunja will only read a password from a terminal, so it goes
# in the argument list -- inside a microVM whose only processes are this session's.
/app/vikunja/vikunja user reset-password 1 --direct --password "$APP_ADMIN_PASSWORD" >/dev/null

test -s /data/vikunja.db
cleanup
trap - EXIT HUP INT TERM

unset APP_BASE_URL APP_ADMIN_PASSWORD SECRET_KEY_BASE
exec /app/vikunja/vikunja web
