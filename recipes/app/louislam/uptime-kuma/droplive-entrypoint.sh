#!/bin/sh
set -eu

seed_values=0
for value in "${DROPLIVE_ADMIN_PASSWORD:-}" "${DROPLIVE_STABLE_URL:-}" \
  "${DROPLIVE_FAILING_URL:-}" "${DROPLIVE_FLAPPING_URL:-}"; do
  if [ -n "$value" ]; then seed_values=$((seed_values + 1)); fi
done
"$@" &
server_pid=$!
trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT

if [ "$seed_values" -eq 4 ]; then
  node /usr/local/lib/droplive-uptime-kuma-seed.cjs
fi
wait "$server_pid"
