#!/usr/bin/env bash
set -euo pipefail

: "${DROPLIVE_PUBLIC_ORIGIN:?DropLive supplies the public origin}"
export KOLU_ALLOWED_ORIGINS="$DROPLIVE_PUBLIC_ORIGIN"

cd /workspace
/opt/droplive/bin/world-workspace.sh

kolu web --bind 0.0.0.0 --port 7681 &
server_pid=$!

cleanup() {
  kill "$server_pid" 2>/dev/null || true
  wait "$server_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

for _ in $(seq 1 120); do
  if curl --fail --silent http://127.0.0.1:7681/api/health | grep -qx kolu; then
    break
  fi
  if ! kill -0 "$server_pid" 2>/dev/null; then
    wait "$server_pid"
  fi
  sleep 0.25
done
curl --fail --silent http://127.0.0.1:7681/api/health | grep -qx kolu

kolu_padi() {
  kolu --state-root "$KOLU_PADI_STATE_DIR" "$@"
}

# HTTP readiness is earlier than Padi readiness. Wait for the exact Padi state
# root owned by this Kolu server before creating the real terminal layout.
for _ in $(seq 1 120); do
  if kolu_padi ls >/dev/null 2>&1; then
    break
  fi
  if ! kill -0 "$server_pid" 2>/dev/null; then
    wait "$server_pid"
  fi
  sleep 0.25
done
kolu_padi ls >/dev/null

release_id=$(kolu_padi create --toplevel --cwd /workspace/northstar-relay --intent "Release 2.8 · failing gate" -- bash -lc './scripts/release-checks || true; exec bash')
kolu_padi create --parent "$release_id" --cwd /workspace/northstar-relay --intent "Release gate · file watcher" -- bash -lc './scripts/watch-tests' >/dev/null
kolu_padi create --toplevel --cwd /workspace/northstar-relay --intent "Web console · development server" -- bash -lc './scripts/dev-server' >/dev/null
kolu_padi create --toplevel --cwd /workspace/northstar-relay --intent "Issue 319 · cleanup worker" -- bash -lc './scripts/export-worker; exec bash' >/dev/null
kolu_padi create --toplevel --cwd /workspace/northstar-relay --intent "Northstar · completed briefing" -- bash -lc './scripts/briefing; printf "\n[briefing] complete\n"; exec bash' >/dev/null

wait "$server_pid"
