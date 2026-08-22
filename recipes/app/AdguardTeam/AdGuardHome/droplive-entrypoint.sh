#!/bin/sh
set -eu

: "${ADGUARD_ADMIN_PASSWORD:?DropLive generates the AdGuard Home admin password}"

config=/opt/adguardhome/conf/AdGuardHome.yaml
work=/opt/adguardhome/work

mkdir -p "$(dirname "$config")" "$work"

if [ ! -s "$config" ]; then
  # The upstream installer changes the web port from 3000 to 80. Complete the
  # same setup through its API and keep the public DropLive port stable.
  /opt/adguardhome/AdGuardHome --no-check-update -c "$config" -w "$work" &
  setup_pid=$!
  trap 'kill "$setup_pid" 2>/dev/null || true' EXIT INT TERM

  until wget -qO /dev/null http://127.0.0.1:3000/control/install/get_addresses; do
    if ! kill -0 "$setup_pid" 2>/dev/null; then
      wait "$setup_pid"
      exit 1
    fi
    sleep 0.2
  done

  wget -qO /dev/null \
    --header='Content-Type: application/json' \
    --post-data="{\"web\":{\"ip\":\"0.0.0.0\",\"port\":3000},\"dns\":{\"ip\":\"0.0.0.0\",\"port\":53,\"autofix\":true},\"username\":\"admin\",\"password\":\"${ADGUARD_ADMIN_PASSWORD}\"}" \
    http://127.0.0.1:3000/control/install/configure

  kill "$setup_pid"
  wait "$setup_pid" || true
  trap - EXIT INT TERM
fi

exec /opt/adguardhome/AdGuardHome \
  --no-check-update \
  -c "$config" \
  -w "$work"
