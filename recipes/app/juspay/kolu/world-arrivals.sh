#!/usr/bin/env bash
set -euo pipefail

world_path=${DROPLIVE_WORLD_PATH:?DROPLIVE_WORLD_PATH is required}
timeline="$world_path/timeline.json"
log=/workspace/northstar-relay/var/activity.log
start=$(date +%s)

jq -c '.[]' "$timeline" | while IFS= read -r event; do
  due=$(jq -r '.after_seconds' <<<"$event")
  now=$(date +%s)
  wait_for=$((start + due - now))
  if (( wait_for > 0 )); then sleep "$wait_for"; fi
  jq -r '
    if .kind == "chat-message" then
      "[" + (.after_seconds|tostring) + "s · chat] " + .payload.author_id + ": " + .payload.text
    elif .kind == "incoming-email" then
      "[" + (.after_seconds|tostring) + "s · email] " + .payload.from_id + " — " + .payload.subject + ": " + .payload.snippet
    else
      "[" + (.after_seconds|tostring) + "s · webhook] " + .payload.event + " · " + .payload.invoice_id
    end
  ' <<<"$event" >> "$log"
done
