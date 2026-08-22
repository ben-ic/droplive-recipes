#!/bin/sh
set -eu

: "${APP_URL:?DropLive supplies the public origin}"
export PAPERLESS_URL="$APP_URL"

exec /init "$@"
