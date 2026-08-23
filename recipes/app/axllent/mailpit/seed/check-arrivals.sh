#!/usr/bin/env bash
# Prove the arrivals adapter does what it claims, against the real image.
#
#   ./seed/check-arrivals.sh
#
# Builds the recipe, runs it with a world whose timeline uses short delays, and
# asserts:
#
#   1. no mail arrives before its delay
#   2. the one supported kind arrives after its delay, as a real message
#   3. a restart does not deliver it twice
#   4. the kinds that are not mail are skipped, and the app keeps running
#
# The timeline it is given carries all three kinds the world uses, so the two
# this mailbox refuses are exercised rather than assumed. Time is measured from
# the moment the seed finishes, because that is when the adapter starts.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
NAME=mailpit-arrivals-check
PORT=${PORT:-19498}
WORLD=$(mktemp -d)
trap 'docker rm -f "$NAME" >/dev/null 2>&1 || true; rm -rf "$WORLD"' EXIT

cat >"$WORLD/timeline.json" <<'JSON'
[
 {"after_seconds": 2, "id": "check-chat", "kind": "chat-message",
  "payload": {"author_id": "lucas-meyer", "channel_id": "channel-lumen-renewal",
              "text": "50k and 75k complete with the branch."}},
 {"after_seconds": 8, "id": "check-email", "kind": "incoming-email",
  "payload": {"from_id": "priya-raman", "to_id": "maya-chen", "customer_id": "lumen",
              "subject": "Arrivals check subject",
              "body_text": "The 48,002-row sample completed in 1m34s.\n\nPriya"}},
 {"after_seconds": 12, "id": "check-webhook", "kind": "webhook",
  "payload": {"event": "finance.invoice.paid", "customer_id": "lumen",
              "invoice_id": "inv-4471", "payment_id": "pay-4471", "amount_cents": 41200}}
]
JSON

fail() { echo "FAIL: $*" >&2; docker logs "$NAME" 2>&1 | tail -20 >&2; exit 1; }

# How many messages in the mailbox carry the check's subject.
arrived() {
  curl -s -m 10 "http://127.0.0.1:$PORT/api/v1/search?query=$1" |
    python3 -c 'import json,sys; print(len(json.load(sys.stdin).get("messages") or []))' 2>/dev/null || echo 0
}
total() {
  curl -s -m 10 "http://127.0.0.1:$PORT/api/v1/messages?limit=1" |
    python3 -c 'import json,sys; print(json.load(sys.stdin).get("total", 0))' 2>/dev/null || echo 0
}

echo "building the recipe"
docker build -q -t "$NAME-image" "$HERE/.." >/dev/null

docker rm -f "$NAME" >/dev/null 2>&1 || true
docker run -d --name "$NAME" -p "$PORT:8025" \
  -v "$WORLD:/run/droplive/world:ro" \
  -e DROPLIVE_WORLD_PATH=/run/droplive/world "$NAME-image" >/dev/null

for _ in $(seq 1 180); do
  docker logs "$NAME" 2>&1 | grep -qE "ingested the Northstar mail|already holds messages" && break
  sleep 1
done
docker logs "$NAME" 2>&1 | grep -qE "ingested the Northstar mail|already holds messages" || fail "the seed never finished"
started=$(date +%s)
seeded=$(total)
echo "seed finished with $seeded messages; the timeline starts now"

# 1. nothing before its delay. The supported event is at 8s.
sleep 4
[ "$(arrived 'Arrivals+check+subject')" -eq 0 ] || fail "the mail arrived before its delay"
[ "$(total)" -eq "$seeded" ] || fail "something arrived before its delay"
echo "ok: nothing arrived in the first 4 seconds"

# 2. it arrives after its delay, as a message the mailbox parsed.
while [ $(( $(date +%s) - started )) -lt 14 ]; do sleep 1; done
[ "$(arrived 'Arrivals+check+subject')" -eq 1 ] || fail "the mail did not arrive exactly once"
echo "ok: the mail arrived after its delay"

# 4. the two kinds that are not mail were skipped, out loud, and only the mail
#    was delivered.
while [ $(( $(date +%s) - started )) -lt 18 ]; do sleep 1; done
docker logs "$NAME" 2>&1 | grep -q "skipped: check-chat" || fail "the chat message was not reported as skipped"
docker logs "$NAME" 2>&1 | grep -q "skipped: check-webhook" || fail "the webhook was not reported as skipped"
docker logs "$NAME" 2>&1 | grep -q "the timeline is finished" || fail "the adapter did not finish"
after_all=$(total)
[ "$after_all" -eq $(( seeded + 1 )) ] || fail "expected $(( seeded + 1 )) messages, found $after_all"
curl -sf -m 10 -o /dev/null "http://127.0.0.1:$PORT/" || fail "the app is not serving"
echo "ok: only the mail was delivered, and the app kept running"

# 3. a restart does not deliver anything twice. Mailpit has no database, so the
#    mailbox empties and is seeded again; the arrival must come back exactly
#    once, neither missing nor doubled.
docker restart "$NAME" >/dev/null
for _ in $(seq 1 120); do
  if [ "$(docker logs "$NAME" 2>&1 | grep -c 'the timeline is finished')" -ge 2 ]; then
    break
  fi
  sleep 1
done
sleep 3
[ "$(total)" -eq "$after_all" ] || fail "a restart left $(total) messages, not $after_all"
[ "$(arrived 'Arrivals+check+subject')" -eq 1 ] || fail "a restart duplicated the arrival"
echo "ok: a restart delivered nothing twice"

echo "PASS"
