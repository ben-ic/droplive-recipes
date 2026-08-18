#!/bin/sh
set -eu

# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=none name=ADMIN_PASSWORD capability=owner-login username=admin
: "${DATABASE_URL:?DropLive must attach managed PostgreSQL}"
: "${ADMIN_PASSWORD:?DropLive must generate the initial owner password}"
# Internal to this µVM. Etherpad reads it back from APIKEY.txt to authenticate
# its own API clients; nothing outside the machine ever sees it, and no visitor
# is ever shown it.
#
# Generate this internal key when the caller does not provide one. It is created
# at container start and is never baked into the image.
ETHERPAD_INTERNAL_API_KEY="${ETHERPAD_INTERNAL_API_KEY:-$(od -An -tx1 -N32 /dev/urandom | tr -d ' \n')}"
export ETHERPAD_INTERNAL_API_KEY
: "${PUBLIC_URL:?DropLive must set the public application URL}"

# Etherpad's v3 default SSO REST mode requires an external OAuth provider. The
# quick-install path keeps the normal Basic-auth owner UI and selects the
# documented API-key mode for local lifecycle verification and integrations.
# The key lives below the managed data directory, so restart/redeploy and
# backup/restore keep the same credential. The process runs as the upstream
# unprivileged user and owns this directory in the official image.
umask 077
printf '%s\n' "$ETHERPAD_INTERNAL_API_KEY" > /opt/etherpad-lite/var/APIKEY.txt
export AUTHENTICATION_METHOD=apikey

# Etherpad checks for var/installed_plugins.json at boot and, when it is absent,
# runs a one-time plugin migration that shells out to
# `pnpm ls --long --json --depth=0 --no-production`. That command needs writable
# node/pnpm state which the read-only root filesystem does not provide, it exits
# non-zero, and Etherpad treats that as fatal: "Error occurred while starting
# Etherpad", then Exiting, then a crash loop until the readiness deadline.
#
# The file lives in the managed data directory, which every demo session gets
# EMPTY. On a persistent deploy this migration runs once on the very first boot
# and the written file suppresses it forever after, which is why the corpus
# evidence never saw it. Here every session is a first boot, so it fires every
# single launch.
#
# Seeding the exact shape `persistInstalledPlugins` writes skips the migration
# without pretending anything is installed: installer.ts reads this file back and
# iterates `installedPlugins.plugins`, so the empty list is both truthful and
# well formed. A demo installs no plugins.
if [ ! -e /opt/etherpad-lite/var/installed_plugins.json ]; then
  printf '%s\n' '{"plugins":[]}' > /opt/etherpad-lite/var/installed_plugins.json
fi

# Etherpad's Docker settings accept a single PostgreSQL connection string as
# DB_URL. Keep the generic DropLive binding runtime-only and do not bake it into
# the image or leave an unused alias for application code to misinterpret.
export DB_URL="$DATABASE_URL"
unset DATABASE_URL

exec "$@"
