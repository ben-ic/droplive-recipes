#!/bin/sh
set -eu

: "${MEILI_MASTER_KEY:?DropLive must generate MEILI_MASTER_KEY}"
case "$MEILI_MASTER_KEY" in
  *[!A-Za-z0-9_-]*|'') exit 64 ;;
esac

seed_marker=/meili_data/.droplive-company-seed-v1
/bin/meilisearch &
meili_pid=$!
trap 'kill "$meili_pid" 2>/dev/null || true; wait "$meili_pid" 2>/dev/null || true' EXIT INT TERM

if ! test -e "$seed_marker"; then
  for attempt in $(seq 1 45); do
    if curl --fail --silent http://127.0.0.1:7700/health >/dev/null; then break; fi
    sleep 1
  done
  curl --fail --silent http://127.0.0.1:7700/health >/dev/null
  curl --fail --silent --header "Authorization: Bearer $MEILI_MASTER_KEY" --header 'Content-Type: application/json' \
    --data '[{"id":"release-readiness","title":"Release readiness","body":"Confirm scope, owner, and customer communication before release."},{"id":"customer-notes","title":"Customer notes","body":"Three customer interviews are ready for review."},{"id":"support-queue","title":"Support queue","body":"Two priority support items need an owner."}]' \
    http://127.0.0.1:7700/indexes/northstar/documents >/dev/null
  touch "$seed_marker"
fi
unset MEILI_MASTER_KEY
wait "$meili_pid"
