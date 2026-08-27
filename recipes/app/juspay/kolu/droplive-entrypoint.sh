#!/usr/bin/env bash
set -euo pipefail

test -n "${DROPLIVE_PUBLIC_ORIGIN:-}"
export KOLU_ALLOWED_ORIGINS="$DROPLIVE_PUBLIC_ORIGIN"

/opt/droplive/bin/world-workspace.sh
/opt/droplive/bin/world-arrivals.sh &
arrivals_pid=$!

kolu web --bind 0.0.0.0 --port 7681 &
server_pid=$!

cleanup() {
  kill "$arrivals_pid" "$server_pid" 2>/dev/null || true
  wait "$arrivals_pid" "$server_pid" 2>/dev/null || true
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

release_id=$(kolu create --toplevel --cwd /workspace/northstar-relay --intent "Release 2.8 · readiness" -- bash -lc './scripts/release-checks; exec bash')
kolu create --parent "$release_id" --cwd /workspace/northstar-relay --intent "World activity · live" -- bash -lc './scripts/activity' >/dev/null
kolu create --toplevel --cwd /workspace/northstar-relay --intent "Issue 318 · worker fix" -- bash -lc 'printf "\nIssue 318 · scheduled export timeout\n\n"; git status --short; git diff -- config/export-worker.conf; ./services/relay-core/worker.sh; exec bash' >/dev/null
kolu create --toplevel --cwd /workspace/northstar-relay --intent "Lumen · support context" -- bash -lc 'printf "\n"; sed -n "1,160p" docs/lumen-support.md; printf "\nRecent support work\n\n"; sed -n "1,8p" data/tasks.tsv; exec bash' >/dev/null
kolu create --toplevel --cwd /workspace/northstar-relay --intent "Northstar · operating brief" -- bash -lc './scripts/briefing; exec bash' >/dev/null

wait "$server_pid"
