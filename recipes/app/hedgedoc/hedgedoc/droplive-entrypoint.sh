#!/bin/sh
set -eu

# HedgeDoc calls its database URL CMD_DB_URL. DropLive's generic companion
# contract exposes DATABASE_URL, so map that runtime-only value at the last
# possible moment. This keeps credentials out of the immutable image and makes
# a missing managed companion fail closed before the app can receive traffic.
: "${DATABASE_URL:?DropLive must attach the managed PostgreSQL companion}"
# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=SESSION_SECRET
: "${SESSION_SECRET:?DropLive must generate the stable session secret}"
: "${APP_URL:?DropLive must derive the assigned public origin}"

: "${CMD_DB_URL:=${DATABASE_URL}}"
: "${CMD_SESSION_SECRET:=${SESSION_SECRET}}"

# CMD_DOMAIN is a bare hostname in HedgeDoc's configuration. APP_URL is the
# platform's https:// origin, so strip scheme and any path before passing it
# upstream. An explicit CMD_DOMAIN remains an escape hatch for a future
# platform-native binding and is never user-supplied in this recipe.
domain="${APP_URL#*://}"
domain="${domain%%/*}"
: "${CMD_DOMAIN:=${domain}}"

export CMD_DB_URL CMD_SESSION_SECRET CMD_DOMAIN

# HedgeDoc 1.11.1 still merges the legacy `DATABASE_URL` setting and then
# indexes an optional config file without a guard. Leaving the generic
# companion variable in the process environment therefore triggers its
# upstream `fileConfig[key]` TypeError whenever a database URL is present.
# After the values have been copied to the documented CMD_* names, remove the
# generic aliases so the official image receives the same environment shape as
# its supported Compose deployment.
unset DATABASE_URL SESSION_SECRET APP_URL

exec /usr/local/bin/docker-entrypoint.sh "$@"
