#!/bin/sh
set -eu

: "${ROOT_PASSWORD:?DropLive generates the Audiobookshelf root password}"

tini -- "$@" &
app_pid=$!

stop_app() {
  kill -TERM "$app_pid" 2>/dev/null || true
  wait "$app_pid" 2>/dev/null || true
}
trap stop_app INT TERM EXIT

node /usr/local/lib/droplive-audiobookshelf-bootstrap.mjs

trap - EXIT
wait "$app_pid"
