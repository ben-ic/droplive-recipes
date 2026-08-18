#!/bin/sh
set -eu

: "${NEXTAUTH_URL:?DropLive must derive the assigned public HTTPS origin}"
case "${NEXTAUTH_URL}" in
  https://*|http://localhost*) ;;
  *) echo "NEXTAUTH_URL must be the assigned HTTPS public origin" >&2; exit 64 ;;
esac

exec /init "$@"
