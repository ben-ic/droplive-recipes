#!/bin/sh
set -eu

: "${KOMGA_ADMIN_PASSWORD:?KOMGA_ADMIN_PASSWORD is required}"

config_dir="${KOMGA_CONFIGDIR:-/config}"
admin_email="${KOMGA_ADMIN_EMAIL:-admin@example.org}"
startup_log="$(mktemp /tmp/komga-startup.XXXXXX)"
reset_log="$(mktemp /tmp/komga-reset.XXXXXX)"

cleanup() {
  rm -f "$startup_log" "$reset_log"
}
stop_process() {
  kill "$1" 2>/dev/null || true
  wait "$1" 2>/dev/null || true
}
stop_child() {
  stop_process "$app_pid"
  cleanup
}
trap 'stop_child; exit 143' INT TERM

java -Dspring.profiles.include=docker --enable-native-access=ALL-UNNAMED \
  -jar /app/application.jar \
  --spring.profiles.active=noclaim \
  --spring.config.additional-location="file:${config_dir}/" \
  "$@" >"$startup_log" 2>&1 &
app_pid=$!

reset_ok=false
for attempt in $(seq 1 30); do
  if ! kill -0 "$app_pid" 2>/dev/null; then
    cat "$startup_log" >&2
    exit 1
  fi

  if curl -fsS http://127.0.0.1:25600/ >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! curl -fsS http://127.0.0.1:25600/ >/dev/null 2>&1; then
  cat "$startup_log" >&2
  stop_child
  exit 1
fi

# Komga creates the initial user after the web server starts. Allow its first
# background tasks to finish before stopping it for the CLI reset.
sleep 8
stop_process "$app_pid"

for attempt in $(seq 1 3); do
  : >"$reset_log"
  java -Dspring.profiles.include=docker --enable-native-access=ALL-UNNAMED \
    -jar /app/application.jar \
    --spring.profiles.active=noclaim \
    --reset="$admin_email" \
    --newpassword="$KOMGA_ADMIN_PASSWORD" \
    --server.port=0 \
    --spring.config.additional-location="file:${config_dir}/" \
    >"$reset_log" 2>&1 &
  reset_pid=$!

  for reset_attempt in $(seq 1 15); do
    if grep -q 'Reset password for user:' "$reset_log"; then
      reset_ok=true
      break
    fi
    if grep -q 'User does not exist:' "$reset_log"; then
      break
    fi
    if ! kill -0 "$reset_pid" 2>/dev/null; then
      break
    fi
    sleep 1
  done
  sleep 2
  stop_process "$reset_pid"
  [ "$reset_ok" = true ] && break
done

if [ "$reset_ok" != true ]; then
  cat "$startup_log" "$reset_log" >&2
  cleanup
  exit 1
fi

cleanup
trap - INT TERM
exec java -Dspring.profiles.include=docker --enable-native-access=ALL-UNNAMED \
  -jar /app/application.jar \
  --spring.profiles.active=noclaim \
  --spring.config.additional-location="file:${config_dir}/" \
  "$@"
