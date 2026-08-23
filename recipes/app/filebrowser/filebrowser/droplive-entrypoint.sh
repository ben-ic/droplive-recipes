#!/bin/sh
# Create File Browser's database, then start it.
#
# Everything here runs BEFORE the server does. File Browser keeps its users and
# settings in a Bolt database, which allows exactly one process to hold it open,
# so the CLI and the server cannot both have it. Doing the setup first is not a
# workaround: `filebrowser config init` and `filebrowser users add` are the
# commands the project documents for exactly this.
set -eu

DB=/database.db
ROOT=/srv

# droplive: generate=hex64 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=APP_ADMIN_PASSWORD capability=owner-login username=maya
: "${APP_ADMIN_PASSWORD:?DropLive must generate the initial owner password}"

if [ "${#APP_ADMIN_PASSWORD}" -lt 12 ]; then
  echo "APP_ADMIN_PASSWORD must contain at least 12 characters" >&2
  exit 64
fi

# IDEMPOTENT ON FILE BROWSER'S OWN DATABASE: it is created here exactly once, and
# a restart finds it and leaves the account alone.
if [ ! -f "$DB" ]; then
  /filebrowser config init --database "$DB" --root "$ROOT" --address 0.0.0.0 --port 80 \
    --branding.name "Northstar Relay" >/dev/null
  # The image otherwise writes admin/admin into a fresh database and prints
  # nothing, which is a published credential on a live demo.
  /filebrowser users add maya "$APP_ADMIN_PASSWORD" --database "$DB" --perm.admin >/dev/null
  echo "[droplive] created the File Browser database and its owner" >&2
fi

# A directory's date is the one thing a build cannot set: COPY creates every
# folder fresh, and BuildKit stamps a directory with the layer's own time however
# the build tries to correct it. On a live filesystem it just works. A folder's
# date is the date of the newest thing in it, deepest first so a parent sees a
# child that has already been corrected.
find "$ROOT" -depth -type d -exec sh -c \
  'newest=$(ls -t "$1" 2>/dev/null | head -1); [ -n "$newest" ] && touch -r "$1/$newest" "$1" || true' \
  _ {} \;

unset APP_ADMIN_PASSWORD

exec "$@"
