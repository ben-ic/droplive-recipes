#!/usr/bin/env bash
set -euo pipefail

: "${DROPLIVE_PUBLIC_ORIGIN:?DropLive supplies the public origin}"
export KOLU_ALLOWED_ORIGINS="$DROPLIVE_PUBLIC_ORIGIN"

world_ready=false
if [[ -n "${DROPLIVE_WORLD_PATH:-}" ]]; then
  /opt/droplive/bin/world-workspace.sh
  /opt/droplive/bin/world-arrivals.sh &
  arrivals_pid=$!
  world_ready=true
elif [[ "$DROPLIVE_PUBLIC_ORIGIN" != "http://localhost:7681" ]]; then
  printf '%s\n' "Kolu requires the verified DropLive world for a routed session." >&2
  exit 1
fi

kolu web --bind 0.0.0.0 --port 7681 &
server_pid=$!

cleanup() {
  if [[ "$world_ready" == true ]]; then
    kill "$arrivals_pid" 2>/dev/null || true
    wait "$arrivals_pid" 2>/dev/null || true
  fi
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

# The build readiness probe has no session world to mount. It only proves that
# the pinned Kolu binary serves. A real session always has the verified world;
# only that path creates the disposable workspace and its terminal layout.
if [[ "$world_ready" != true ]]; then
  wait "$server_pid"
  exit $?
fi

release_id=$(kolu create --toplevel --cwd /workspace/northstar-relay --intent "Release 2.8 · readiness" -- bash -lc './scripts/release-checks; exec bash')
kolu create --parent "$release_id" --cwd /workspace/northstar-relay --intent "World activity · live" -- bash -lc './scripts/activity' >/dev/null
kolu create --toplevel --cwd /workspace/northstar-relay --intent "Issue 318 · worker fix" -- bash -lc 'printf "\nIssue 318 · scheduled export timeout\n\n"; git status --short; git diff -- config/export-worker.conf; ./services/relay-core/worker.sh; exec bash' >/dev/null
kolu create --toplevel --cwd /workspace/northstar-relay --intent "Lumen · support context" -- bash -lc 'printf "\n"; sed -n "1,160p" docs/lumen-support.md; printf "\nRecent support work\n\n"; sed -n "1,8p" data/tasks.tsv; exec bash' >/dev/null
kolu create --toplevel --cwd /workspace/northstar-relay --intent "Northstar · operating brief" -- bash -lc './scripts/briefing; exec bash' >/dev/null

wait "$server_pid"
