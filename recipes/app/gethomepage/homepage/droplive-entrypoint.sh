#!/bin/sh
set -eu

: "${APP_URL:?DropLive supplies the public application URL}"

mkdir -p /app/config
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
