#!/bin/sh
set -eu

# The first administrator is created once from the generated password and the
# recipe-defaulted `owner` username. Existing accounts are never overwritten.
# droplive: generate=hex64 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=GITEA_ADMIN_PASSWORD capability=owner-login username=owner

: "${APP_BASE_URL:?DropLive must derive APP_BASE_URL from the public origin}"
: "${GITEA_ADMIN_EMAIL:?The owner must supply GITEA_ADMIN_EMAIL}"
: "${GITEA_ADMIN_PASSWORD:?DropLive must generate GITEA_ADMIN_PASSWORD}"
# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=GITEA_SECRET_KEY
: "${GITEA_SECRET_KEY:?DropLive must generate GITEA_SECRET_KEY}"
# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=GITEA_INTERNAL_TOKEN
: "${GITEA_INTERNAL_TOKEN:?DropLive must generate GITEA_INTERNAL_TOKEN}"
: "${GITEA_ADMIN_USERNAME:=owner}"

public_origin=${APP_BASE_URL%/}
case "$public_origin" in
  https://*) ;;
  *)
    echo '[gitea-init] APP_BASE_URL must be an absolute HTTPS origin.' >&2
    exit 64
    ;;
esac
ROOT_URL=$public_origin/
export ROOT_URL
unset APP_BASE_URL public_origin

case "$GITEA_ADMIN_EMAIL" in
  *@*.*) ;;
  *)
    echo '[gitea-init] GITEA_ADMIN_EMAIL must be a plausible email address.' >&2
    exit 64
    ;;
esac

case "$GITEA_ADMIN_USERNAME" in
  ''|*[!A-Za-z0-9._-]*)
    echo '[gitea-init] GITEA_ADMIN_USERNAME may contain only letters, digits, dot, underscore, and hyphen.' >&2
    exit 64
    ;;
esac

validate_lowerhex_secret() {
  secret_name=$1
  eval "secret_value=\${$secret_name}"
  secret_length=${#secret_value}
  secret_charset=lowerhex
  test -z "$(printf '%s' "$secret_value" | tr -d '0-9a-f')" || secret_charset=other
  if test "$secret_length" -ne 64 || test "$secret_charset" != lowerhex; then
    echo "[gitea-init] $secret_name shape rejected: observed_length=$secret_length observed_charset=$secret_charset required=64-lowerhex." >&2
    exit 64
  fi
  unset secret_name secret_value secret_length secret_charset
}

validate_lowerhex_secret GITEA_ADMIN_PASSWORD
validate_lowerhex_secret GITEA_SECRET_KEY
validate_lowerhex_secret GITEA_INTERNAL_TOKEN

SECRET_KEY=$GITEA_SECRET_KEY
GITEA__security__INTERNAL_TOKEN=$GITEA_INTERNAL_TOKEN
export SECRET_KEY GITEA__security__INTERNAL_TOKEN
unset GITEA_SECRET_KEY GITEA_INTERNAL_TOKEN

# Reuse the pinned image's own environment-to-app.ini implementation rather
# than maintaining a second configuration renderer. It is idempotent and only
# rewrites explicitly supplied settings after first install.
echo '[gitea-init] Rendering the pinned upstream configuration.'
timeout -s TERM 30 /etc/s6/gitea/setup

echo '[gitea-init] Running the pinned release database migrations before traffic.'
timeout -s TERM 300 su-exec "$USER" /usr/local/bin/gitea migrate

all_users=$(timeout -s TERM 60 su-exec "$USER" /usr/local/bin/gitea admin user list)
user_count=$(printf '%s\n' "$all_users" | awk 'NR > 1 && NF { count++ } END { print count + 0 }')
owner_record=$(printf '%s\n' "$all_users" | awk -v name="$GITEA_ADMIN_USERNAME" '$2 == name { print $2 "\t" $3 "\t" $5 }')

if test "$user_count" -eq 0; then
  echo "[gitea-init] Creating the first administrator '$GITEA_ADMIN_USERNAME'."
  admin_password=$GITEA_ADMIN_PASSWORD
  unset GITEA_ADMIN_PASSWORD
  timeout -s TERM 60 su-exec "$USER" /usr/local/bin/gitea admin user create \
    --username "$GITEA_ADMIN_USERNAME" \
    --password "$admin_password" \
    --email "$GITEA_ADMIN_EMAIL" \
    --admin \
    --must-change-password=false
  unset admin_password
elif test "$owner_record" = "$GITEA_ADMIN_USERNAME	$GITEA_ADMIN_EMAIL	true"; then
  echo "[gitea-init] Existing administrator '$GITEA_ADMIN_USERNAME' matches the managed bootstrap identity."
  unset GITEA_ADMIN_PASSWORD
else
  echo '[gitea-init] Refusing to overwrite a non-empty database whose managed administrator identity does not match.' >&2
  exit 65
fi

unset all_users user_count owner_record GITEA_ADMIN_EMAIL

echo '[gitea-runtime] Starting the official Gitea web process on port 3000; SSH and Actions are disabled.'
exec /usr/bin/s6-svscan /etc/s6-droplive
