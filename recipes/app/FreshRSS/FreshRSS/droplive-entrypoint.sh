#!/bin/sh
set -eu

if [ -z "${FRESHRSS_PASSWORD:-}" ] || [ -z "${DROPLIVE_FEED_URL:-}" ]; then
  echo "FreshRSS setup requires its DropLive password and feed binding" >&2
  exit 64
fi

exec ./Docker/entrypoint.sh "$@"
