#!/bin/sh
set -eu

: "${APP_URL:?DropLive supplies the public application URL}"

exec /init "$@"
