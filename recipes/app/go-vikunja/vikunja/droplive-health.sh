#!/bin/sh
set -eu

body=$(/bin/busybox wget -q -O - http://127.0.0.1:3456/api/v2/health)
case "$body" in
  *'"status":"OK"'*) exit 0 ;;
  *) exit 1 ;;
esac
