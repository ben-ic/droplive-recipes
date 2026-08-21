#!/bin/sh
set -eu

: "${DROPLIVE_PUBLIC_ORIGIN:?DropLive must derive the public URL}"
: "${CB_ADMIN_PASSWORD:?DropLive must generate the CloudBeaver admin password}"

export CB_SERVER_URL="$DROPLIVE_PUBLIC_ORIGIN"

exec "$@"
