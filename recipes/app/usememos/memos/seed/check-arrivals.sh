#!/usr/bin/env bash
# Prove the arrivals adapter does what it claims, against the real image.
#
#   ./seed/check-arrivals.sh
#
# Builds the recipe, runs it with a world whose timeline uses short delays, and
# asserts the four things worth asserting:
#
#   1. nothing arrives before its delay
#   2. a supported event arrives after its delay
#   3. a restart does not deliver it twice
#   4. an unsupported kind is skipped and the app keeps running
#
# Time is measured from the moment the seed finishes, because that is when the
# adapter starts; measuring from `docker run` measures the image pull as well and
# will tell you an event was early when it was not.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
NAME=memos-arrivals-check
PORT=${PORT:-19496}
PASSWORD=check-only-password-1234
WORLD=$(mktemp -d)
trap 'docker rm -f "$NAME" >/dev/null 2>&1 || true; docker volume rm "$NAME-data" >/dev/null 2>&1 || true; rm -rf "$WORLD"' EXIT

cat >"$WORLD/timeline.json" <<'JSON'
[
 {"after_seconds": 2, "id": "check-unsupported", "kind": "seismic-event",
  "payload": {"magnitude": 4}},
 {"after_seconds": 6, "id": "check-email", "kind": "incoming-email",
  "payload": {"from_id": "priya-raman", "to_id": "maya-chen", "customer_id": "lumen",
              "subject": "Export is still timing out",
              "body_text": "The 48,002-row sample completed in 1m34s.\n\nPriya"}},
 {"after_seconds": 10, "id": "check-chat", "kind": "chat-message",
  "payload": {"author_id": "lucas-meyer", "channel_id": "channel-lumen-renewal",
              "text": "50k and 75k complete with the branch."}},
 {"after_seconds": 14, "id": "check-webhook", "kind": "webhook",
  "payload": {"event": "finance.invoice.paid", "customer_id": "lumen",
              "invoice_id": "inv-4471", "payment_id": "pay-4471", "amount_cents": 41200}}
]
JSON

fail() { echo "FAIL: $*" >&2; docker logs "$NAME" 2>&1 | tail -20 >&2; exit 1; }

memo_count() {
  local token
  token=$(curl -s -m 10 -H 'content-type: application/json' \
    -d "{\"passwordCredentials\":{\"username\":\"maya\",\"password\":\"$PASSWORD\"}}" \
    "http://127.0.0.1:$PORT/api/v1/auth/signin" |
    sed -n 's/.*"accessToken":[[:space:]]*"\([^"]*\)".*/\1/p')
  [ -n "$token" ] || { echo 0; return; }
  curl -s -m 10 -H "authorization: Bearer $token" \
    "http://127.0.0.1:$PORT/api/v1/memos?pageSize=200" |
    grep -o '"content"' | wc -l | tr -d ' '
}

has_memo() {
  local token
  token=$(curl -s -m 10 -H 'content-type: application/json' \
    -d "{\"passwordCredentials\":{\"username\":\"maya\",\"password\":\"$PASSWORD\"}}" \
    "http://127.0.0.1:$PORT/api/v1/auth/signin" |
    sed -n 's/.*"accessToken":[[:space:]]*"\([^"]*\)".*/\1/p')
  curl -s -m 10 -H "authorization: Bearer $token" \
    "http://127.0.0.1:$PORT/api/v1/memos?pageSize=200" | grep -qF "$1"
}

echo "building the recipe"
docker build -q -t "$NAME-image" "$HERE/.." >/dev/null

docker rm -f "$NAME" >/dev/null 2>&1 || true
docker volume rm "$NAME-data" >/dev/null 2>&1 || true
docker run -d --name "$NAME" -p "$PORT:5230" -v "$NAME-data:/var/opt/memos" \
  -v "$WORLD:/run/droplive/world:ro" \
  -e DROPLIVE_WORLD_PATH=/run/droplive/world \
  -e MEMOS_OWNER_PASSWORD="$PASSWORD" "$NAME-image" >/dev/null

# The adapter starts when the seed finishes, so that is when the clock starts.
for _ in $(seq 1 120); do
  docker logs "$NAME" 2>&1 | grep -q "seeded .* memos" && break
  sleep 1
done
docker logs "$NAME" 2>&1 | grep -q "seeded .* memos" || fail "the seed never finished"
started=$(date +%s)
seeded=$(memo_count)
echo "seed finished with $seeded memos; the timeline starts now"

# 1. nothing before its delay. The first supported event is at 6s.
sleep 3
if has_memo "Export is still timing out"; then
  fail "the email arrived before its delay"
fi
[ "$(memo_count)" -eq "$seeded" ] || fail "something arrived before its delay"
echo "ok: nothing arrived in the first 3 seconds"

# 2. a supported event arrives after its delay.
while [ $(( $(date +%s) - started )) -lt 9 ]; do sleep 1; done
has_memo "Export is still timing out" || fail "the email did not arrive after its delay"
echo "ok: the email arrived after its delay"

# everything else, then the adapter should stop on its own.
while [ $(( $(date +%s) - started )) -lt 18 ]; do sleep 1; done
has_memo "Lucas Meyer" || fail "the chat message did not arrive"
has_memo "Invoice 4471 paid" || fail "the payment did not arrive"
after_all=$(memo_count)
[ "$after_all" -eq $(( seeded + 3 )) ] ||
  fail "expected $(( seeded + 3 )) memos, found $after_all"
echo "ok: all three supported events arrived, and only those three"

# 4. the unsupported kind was skipped, said so, and did not stop the app.
docker logs "$NAME" 2>&1 | grep -q "skipped: check-unsupported" ||
  fail "the unsupported kind was not reported as skipped"
docker logs "$NAME" 2>&1 | grep -q "the timeline is finished" ||
  fail "the adapter did not finish"
curl -sf -m 10 -o /dev/null "http://127.0.0.1:$PORT/healthz" || fail "the app is not healthy"
echo "ok: the unsupported kind was skipped and the app kept running"

# 3. a restart does not deliver anything twice.
docker restart "$NAME" >/dev/null
for _ in $(seq 1 60); do
  curl -sf -m 5 -o /dev/null "http://127.0.0.1:$PORT/healthz" && break
  sleep 1
done
sleep 20
after_restart=$(memo_count)
[ "$after_restart" -eq "$after_all" ] ||
  fail "a restart changed the count from $after_all to $after_restart"
echo "ok: a restart delivered nothing twice"

echo "PASS"
