#!/bin/sh
set -eu

: "${PAPERLESS_URL:?DropLive supplies the public origin}"

exec /init "$@"
