#!/bin/sh
set -eu

if { [ -n "${FRESHRSS_PASSWORD:-}" ] && [ -z "${DROPLIVE_FEED_URL:-}" ]; } || \
   { [ -z "${FRESHRSS_PASSWORD:-}" ] && [ -n "${DROPLIVE_FEED_URL:-}" ]; }; then
  echo "FreshRSS setup received an incomplete DropLive seed environment" >&2
  exit 64
fi

exec ./Docker/entrypoint.sh "$@"
