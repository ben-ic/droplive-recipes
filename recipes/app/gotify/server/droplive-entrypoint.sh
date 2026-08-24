#!/bin/sh
set -eu

: "${GOTIFY_DEFAULTUSER_PASS:?DropLive must generate GOTIFY_DEFAULTUSER_PASS}"
case "$GOTIFY_DEFAULTUSER_PASS" in
  *[!A-Za-z0-9_-]*|'') exit 64 ;;
esac

data_dir=/app/data
seed_marker=$data_dir/.droplive-company-seed-v1
mkdir -p "$data_dir"

./gotify-app &
gotify_pid=$!
trap 'kill "$gotify_pid" 2>/dev/null || true; wait "$gotify_pid" 2>/dev/null || true' EXIT INT TERM

if ! test -e "$seed_marker"; then
  for attempt in $(seq 1 30); do
    if curl --fail --silent http://127.0.0.1:80/health >/dev/null; then
      break
    fi
    sleep 1
  done
  curl --fail --silent http://127.0.0.1:80/health >/dev/null
  app_json=$(curl --fail --silent --user "admin:$GOTIFY_DEFAULTUSER_PASS" \
    --header 'Content-Type: application/json' --data '{"name":"Northstar Relay"}' \
    http://127.0.0.1:80/application)
  app_token=$(printf '%s' "$app_json" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
  test -n "$app_token"
  curl --fail --silent --data 'title=Release readiness&message=Review starts at 10:00 UTC.&priority=5' "http://127.0.0.1:80/message?token=$app_token" >/dev/null
  curl --fail --silent --data 'title=Customer notes&message=Three interviews are ready for review.&priority=4' "http://127.0.0.1:80/message?token=$app_token" >/dev/null
  curl --fail --silent --data 'title=Support queue&message=Two priority support items need an owner.&priority=4' "http://127.0.0.1:80/message?token=$app_token" >/dev/null
  touch "$seed_marker"
fi

unset GOTIFY_DEFAULTUSER_PASS
wait "$gotify_pid"
