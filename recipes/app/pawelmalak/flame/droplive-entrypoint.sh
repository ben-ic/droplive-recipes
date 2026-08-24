#!/bin/sh
set -eu

# Flame keeps its dashboard database in the managed data directory. Seed only
# before its first database is created; later user edits remain untouched.
if [ ! -e /app/data/db.sqlite ]; then
  node /opt/droplive/flame-seed.js
fi

exec docker-entrypoint.sh "$@"
