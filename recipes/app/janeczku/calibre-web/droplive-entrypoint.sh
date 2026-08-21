#!/bin/sh
set -eu

: "${CALIBRE_ADMIN_PASSWORD:?DropLive generates the Calibre-Web admin password}"

exec /init "$@"
