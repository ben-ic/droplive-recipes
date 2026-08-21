#!/bin/sh
set -eu

: "${APP_URL:?DropLive supplies the public origin}"
export BASEROW_PUBLIC_URL="$APP_URL"

exec /baserow.sh "$@"
