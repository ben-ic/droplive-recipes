#!/bin/sh
set -eu

# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=GLANCE_ADMIN_PASSWORD capability=owner-login username=admin
: "${GLANCE_ADMIN_PASSWORD:?DropLive must generate GLANCE_ADMIN_PASSWORD}"

config=/app/config/glance.yml
template=/opt/droplive/glance.template.yml

if [ -L "$config" ]; then
  printf '%s\n' 'Refusing to use a symbolic-link Glance configuration' >&2
  exit 64
fi

if [ ! -e "$config" ]; then
  umask 077
  temporary=$(mktemp /app/config/.glance.yml.tmp.XXXXXX)
  cleanup() {
    rm -f "$temporary"
  }
  trap cleanup EXIT HUP INT TERM

  password_hash=$(/app/glance password:hash "$GLANCE_ADMIN_PASSWORD")
  session_secret=$(/app/glance secret:make)

  sed \
    -e "s|@@GLANCE_SECRET_KEY@@|$session_secret|" \
    -e "s|@@GLANCE_ADMIN_PASSWORD_HASH@@|$password_hash|" \
    "$template" >"$temporary"

  /app/glance --config "$temporary" config:validate
  mv "$temporary" "$config"
  trap - EXIT HUP INT TERM
fi

# Existing configuration is user data. Validate it, but never replace it with
# the recipe default during restart, redeploy, upgrade, or restore.
/app/glance --config "$config" config:validate
unset GLANCE_ADMIN_PASSWORD password_hash session_secret

exec /app/glance --config "$config"
