#!/bin/sh
set -eu

: "${APP_URL:?DropLive supplies the public application URL}"

mkdir -p /app/config
# Seed the reviewed company dashboard before Homepage's starter files. Both
# sources use names such as settings.yaml and bookmarks.yaml; copying the
# starter files first made the company seed a no-op on every fresh demo.
for source in /opt/droplive/homepage/*.yaml; do
  target="/app/config/${source##*/}"
  if [ ! -e "$target" ]; then
    cp "$source" "$target"
  fi
done

# The upstream skeleton still supplies configuration that this recipe does not
# deliberately replace, such as services and widgets.
for source in /app/src/skeleton/*.yaml; do
  target="/app/config/${source##*/}"
  if [ ! -e "$target" ]; then
    cp "$source" "$target"
  fi
done

# Seed a useful company dashboard only on a new managed volume. Existing user
# configuration always wins.
for source in /opt/droplive/homepage/*.yaml; do
  target="/app/config/${source##*/}"
  if [ ! -e "$target" ]; then
    cp "$source" "$target"
  fi
done

HOMEPAGE_ALLOWED_HOSTS="$(node -e 'process.stdout.write(new URL(process.argv[1]).hostname)' "$APP_URL")"
export HOMEPAGE_ALLOWED_HOSTS

exec docker-entrypoint.sh "$@"
