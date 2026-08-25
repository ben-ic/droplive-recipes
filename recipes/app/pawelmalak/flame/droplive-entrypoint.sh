#!/bin/sh
set -eu

# Flame's image carries an empty database, so its presence does not mean that
# the dashboard data exists. Use our own durable completion marker instead.
# Later user edits remain untouched.
if [ ! -e /app/data/.droplive-seeded ]; then
  node /opt/droplive/flame-seed.js
  : > /app/data/.droplive-seeded
fi

exec docker-entrypoint.sh "$@"
