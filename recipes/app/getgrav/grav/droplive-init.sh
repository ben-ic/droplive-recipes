#!/bin/bash
# Put the Northstar site in place before nginx serves it.
#
# A LinuxServer custom init script, which is the extension point this image
# documents: /custom-cont-init.d runs during startup, before the service, with
# the config volume mounted. That matters here -- /config is a declared volume,
# and a managed block volume can mount empty instead of applying Docker's
# named-volume copy-up, so pages baked into the image path would not be there.
set -euo pipefail

seed=/usr/local/lib/droplive-grav-pages
pages=/config/www/user/pages
site=/config/www/user/config/site.yaml

[[ -d "$seed" ]] || exit 0
[[ -d "$(dirname "$pages")" ]] || exit 0

# IDEMPOTENT ON GRAV'S OWN FIRST PAGE. The image ships 01.home and 02.typography,
# a Grav feature tour; if the home page is still Grav's, this site has not been
# written. After that a restart leaves every page alone, including one a visitor
# edited during the demo.
if [[ ! -e "$pages/01.home/.droplive" ]] && grep -q "Say Hello to Grav" "$pages/01.home/default.md" 2>/dev/null; then
  rm -rf "$pages"/*
  cp -a "$seed"/. "$pages"/
  touch "$pages/01.home/.droplive"
  echo "[droplive] wrote the Northstar site"
fi

if [[ ! -e "$site" ]] || ! grep -q "Northstar" "$site"; then
  mkdir -p "$(dirname "$site")"
  cat >"$site" <<'YAML'
title: 'Northstar Relay'
default_lang: en
author:
  name: 'Northstar Relay'
metadata:
  description: 'A small software company that automates large operational data exports.'
YAML
fi

# Grav's admin redirects every request to its own registration screen until one
# account exists, so an unseeded demo opens on a form asking the visitor to invent
# a login. The account is written here with the password DropLive minted, hashed
# by the same PHP the application uses to check it.
accounts=/config/www/user/accounts
if [[ -n "${GRAV_ADMIN_PASSWORD:-}" && ! -e "$accounts/maya.yaml" ]]; then
  if [[ "${#GRAV_ADMIN_PASSWORD}" -lt 12 ]]; then
    echo "[droplive] GRAV_ADMIN_PASSWORD is too short; leaving Grav without an owner" >&2
  else
    mkdir -p "$accounts"
    hash=$(php -r 'echo password_hash(getenv("GRAV_ADMIN_PASSWORD"), PASSWORD_BCRYPT);')
    cat >"$accounts/maya.yaml" <<YAML
email: maya@northstar-relay.invalid
fullname: 'Maya Chen'
title: 'Co-founder and CEO'
state: enabled
access:
  admin:
    login: true
    super: true
  site:
    login: true
hashed_password: '${hash}'
YAML
    echo "[droplive] created the Grav owner"
  fi
fi

# Grav caches its compiled page tree; pages copied in behind its back are not
# noticed until it is cleared.
rm -rf /config/www/cache/* 2>/dev/null || true
chown -R abc:abc "$pages" "$(dirname "$site")" "$accounts" 2>/dev/null || true
