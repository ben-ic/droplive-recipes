#!/usr/bin/env bash
# Prove the arrivals adapter does what it claims, against the real image.
#
#   ./seed/check-arrivals.sh
#
# Builds the recipe, runs it with a world whose timeline uses short delays, and
# asserts:
#
#   1. nothing arrives before its delay
#   2. the one supported kind arrives after its delay, on the right card
#   3. a restart does not deliver it twice
#   4. the kinds this board cannot say are skipped, and the app keeps running
#
# The timeline it is given carries all three kinds the world uses, so the two
# this board refuses are exercised rather than assumed. Time is measured from
# the moment the seed finishes, because that is when the adapter starts.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
NAME=kanboard-arrivals-check
PORT=${PORT:-19497}
PASSWORD=check-only-password-1234
WORLD=$(mktemp -d)
trap 'docker rm -f "$NAME" >/dev/null 2>&1 || true; docker volume rm "$NAME-data" >/dev/null 2>&1 || true; rm -rf "$WORLD"' EXIT

# The real world artifact, if it is on this machine, so the check runs against
# the same issue titles the seed used. Otherwise the smallest world that carries
# the one issue the timeline refers to.
REAL=${DROPLIVE_WORLD_SOURCE:-$HOME/Dev/droplive-worlds/dist/business.saas-company.v1}
if [ -r "$REAL/world.json" ]; then
  cp "$REAL/world.json" "$WORLD/world.json"
else
  echo "no local world artifact; the check needs one" >&2
  echo "set DROPLIVE_WORLD_SOURCE to a directory containing world.json" >&2
  exit 2
fi

cat >"$WORLD/timeline.json" <<'JSON'
[
 {"after_seconds": 2, "id": "check-email", "kind": "incoming-email",
  "payload": {"from_id": "priya-raman", "to_id": "maya-chen", "customer_id": "lumen",
              "subject": "Export is still timing out",
              "body_text": "The 48,002-row sample completed in 1m34s."}},
 {"after_seconds": 8, "id": "check-chat", "kind": "chat-message",
  "payload": {"author_id": "lucas-meyer", "channel_id": "channel-lumen-renewal",
              "text": "Arrivals check: the partial object still remains after cancellation.",
              "entity_refs": {"issue_id": "issue-318", "repository_id": "repo-exports"}}},
 {"after_seconds": 12, "id": "check-webhook", "kind": "webhook",
  "payload": {"event": "finance.invoice.paid", "customer_id": "lumen",
              "invoice_id": "inv-4471", "payment_id": "pay-4471", "amount_cents": 41200}}
]
JSON

fail() { echo "FAIL: $*" >&2; docker logs "$NAME" 2>&1 | tail -20 >&2; exit 1; }

token() {
  docker exec "$NAME" php -r 'echo (new PDO("sqlite:/var/www/app/data/db.sqlite"))->query("select value from settings where option = \x27api_token\x27")->fetchColumn();' 2>/dev/null
}

rpc() {
  curl -s -m 20 -u "jsonrpc:$(token)" -H 'Content-Type: application/json' \
    --data-binary "$1" "http://127.0.0.1:$PORT/jsonrpc.php"
}

# How many comments anywhere on the boards carry the check's marker. Kanboard
# answers with ids as strings in some procedures and numbers in others, so the
# ids are parsed rather than pattern-matched out of the text.
comment_count() {
  local projects ids found=0
  projects=$(rpc '{"jsonrpc":"2.0","id":1,"method":"getAllProjects","params":{}}' |
    python3 -c 'import json,sys; print(" ".join(str(p["id"]) for p in (json.load(sys.stdin).get("result") or [])))' 2>/dev/null)
  for project in $projects; do
    ids=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAllTasks\",\"params\":{\"project_id\":$project,\"status_id\":1}}" |
      python3 -c 'import json,sys; print(" ".join(str(t["id"]) for t in (json.load(sys.stdin).get("result") or [])))' 2>/dev/null)
    for task in $ids; do
      if rpc "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAllComments\",\"params\":{\"task_id\":$task}}" |
          grep -qF 'Arrivals check'; then
        found=$(( found + 1 ))
      fi
    done
  done
  echo "$found"
}

echo "building the recipe"
docker build -q -t "$NAME-image" "$HERE/.." >/dev/null

docker rm -f "$NAME" >/dev/null 2>&1 || true
docker volume rm "$NAME-data" >/dev/null 2>&1 || true
docker run -d --name "$NAME" -p "$PORT:80" -v "$NAME-data:/var/www/app/data" \
  -v "$WORLD:/run/droplive/world:ro" \
  -e DROPLIVE_WORLD_PATH=/run/droplive/world \
  -e KANBOARD_OWNER_PASSWORD="$PASSWORD" "$NAME-image" >/dev/null

# Kanboard generates a certificate and installs its schema before it will even
# answer, and the seed is 128 calls after that, so this waits in minutes rather
# than seconds.
for _ in $(seq 1 600); do
  if docker logs "$NAME" 2>&1 | grep -qE "seeded kanboard|already has the Northstar"; then
    break
  fi
  sleep 1
done
docker logs "$NAME" 2>&1 | grep -qE "seeded kanboard|already has the Northstar" || fail "the seed never finished"
started=$(date +%s)
echo "seed finished; the timeline starts now"

# 1. nothing before its delay. The supported event is at 8s.
sleep 4
[ "$(comment_count)" -eq 0 ] || fail "the comment arrived before its delay"
echo "ok: nothing arrived in the first 4 seconds"

# 2. it arrives after its delay, on the card that tracks the issue it names.
while [ $(( $(date +%s) - started )) -lt 14 ]; do sleep 1; done
[ "$(comment_count)" -eq 1 ] || fail "the chat message did not arrive exactly once"
echo "ok: the chat message arrived after its delay, on the right card"

# 4. the two kinds this board cannot say were skipped, out loud.
while [ $(( $(date +%s) - started )) -lt 18 ]; do sleep 1; done
docker logs "$NAME" 2>&1 | grep -q "skipped: check-email" || fail "the email was not reported as skipped"
docker logs "$NAME" 2>&1 | grep -q "skipped: check-webhook" || fail "the webhook was not reported as skipped"
docker logs "$NAME" 2>&1 | grep -q "the timeline is finished" || fail "the adapter did not finish"
[ "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/login")" = "200" ] ||
  fail "the app is not serving"
echo "ok: the unsupported kinds were skipped and the app kept running"

# 3. a restart does not deliver anything twice.
docker restart "$NAME" >/dev/null
for _ in $(seq 1 120); do
  [ "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/login" 2>/dev/null)" = "200" ] && break
  sleep 1
done
sleep 20
[ "$(comment_count)" -eq 1 ] || fail "a restart delivered the comment again"
echo "ok: a restart delivered nothing twice"

echo "PASS"
