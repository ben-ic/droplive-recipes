#!/bin/sh
set -eu

# Use the platform's canonical generated names, then map them to Vikunja. This
# keeps the recipe generic and makes the owner password directly revealable.
# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=SECRET_KEY_BASE
# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=APP_ADMIN_PASSWORD capability=owner-login username=owner
: "${SECRET_KEY_BASE:?DropLive must generate SECRET_KEY_BASE}"
: "${APP_ADMIN_PASSWORD:?DropLive must generate APP_ADMIN_PASSWORD}"
: "${APP_BASE_URL:?DropLive must derive APP_BASE_URL from the public origin}"

validate_human_password_16() {
  value=$1
  name=$2
  if test "${#value}" -ne 16; then
    echo "$name must contain exactly 16 URL-safe characters" >&2
    exit 64
  fi
  case "$value" in
    *[!A-Za-z0-9_-]*)
      echo "$name must contain exactly 16 URL-safe characters" >&2
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

marker=/data/.droplive-owner-v1
owner_check=/tmp/droplive-vikunja-owner.$$.txt
owner_username=owner
owner_email=owner@local.invalid
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

if ! test -f "$marker"; then
  if test -s /data/vikunja.db; then
    if ! verify_owner; then
      echo "existing Vikunja database has no matching DropLive owner; refusing unsafe bootstrap" >&2
      exit 65
    fi
  else
    /app/vikunja/vikunja user create \
      --username "$owner_username" \
      --email "$owner_email" \
      --password "$APP_ADMIN_PASSWORD"
    verify_owner
  fi
  touch "$marker"
fi

test -s /data/vikunja.db
verify_owner
cleanup
trap - EXIT HUP INT TERM

unset APP_BASE_URL APP_ADMIN_PASSWORD SECRET_KEY_BASE
exec /app/vikunja/vikunja web
