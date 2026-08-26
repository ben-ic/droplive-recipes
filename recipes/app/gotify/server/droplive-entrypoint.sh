#!/bin/sh
set -eu

: "${GOTIFY_DEFAULTUSER_PASS:?DropLive must generate GOTIFY_DEFAULTUSER_PASS}"
case "$GOTIFY_DEFAULTUSER_PASS" in
  *[!A-Za-z0-9_-]*|'') exit 64 ;;
esac

data_dir=/app/data
seed_marker=$data_dir/.droplive-company-seed-v1
mkdir -p "$data_dir"

./gotify-app &
gotify_pid=$!
trap 'kill "$gotify_pid" 2>/dev/null || true; wait "$gotify_pid" 2>/dev/null || true' EXIT INT TERM

if ! test -e "$seed_marker"; then
  for attempt in $(seq 1 30); do
    if curl --fail --silent http://127.0.0.1:80/health >/dev/null; then
      break
    fi
    sleep 1
  done
  curl --fail --silent http://127.0.0.1:80/health >/dev/null
  create_application() {
    app_json=$(curl --fail --silent --user "admin:$GOTIFY_DEFAULTUSER_PASS" \
      --header 'Content-Type: application/json' --data "{\"name\":\"$1\"}" \
      http://127.0.0.1:80/application)
    printf '%s' "$app_json" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p'
  }
  publish() {
    curl --fail --silent \
      --data-urlencode "title=$2" \
      --data-urlencode "message=$3" \
      --data-urlencode "priority=$4" \
      "http://127.0.0.1:80/message?token=$1" >/dev/null
  }

  release_token=$(create_application 'Release command')
  customer_token=$(create_application 'Customer operations')
  oncall_token=$(create_application 'Platform on-call')
  test -n "$release_token" && test -n "$customer_token" && test -n "$oncall_token"

  publish "$release_token" 'Release 2.8 review starts' 'Maya owns the release review. Confirm the cancellation fixture and customer update before approval.' 8
  publish "$release_token" 'Export cancellation test passed' 'The 50k and 75k cancellation paths now release the worker lease and partial object.' 5
  publish "$release_token" 'Release notes need approval' 'Elena updated the audit-history notes. One product review is still required.' 5
  publish "$release_token" 'Customer communication is scheduled' 'Samira will send the Lumen workaround after the release decision.' 4

  publish "$customer_token" 'Lumen Labs renewal is active' 'Invoice 4471 is open, due 30 August, and is not overdue. Keep billing separate from the export incident.' 6
  publish "$customer_token" 'Three interview summaries are ready' 'Priya, Asha, and Diego feedback is tagged for the release review.' 5
  publish "$customer_token" 'Harbor Mobility risk review' 'The scheduled 75k-row export still needs the tested timeout path before the 12 September renewal.' 7
  publish "$customer_token" 'Ember Commerce follow-up' 'Confirm the CSV header fix with the customer success owner before Friday.' 4

  publish "$oncall_token" 'Scheduled export latency is elevated' 'Two scheduled jobs crossed the legacy-worker warning threshold. Interactive retries remain healthy.' 7
  publish "$oncall_token" 'Worker lease cleanup confirmed' 'The cancellation fixture released all test leases. Continue monitoring the next scheduled run.' 4
  publish "$oncall_token" 'No paging action required' 'The current export incident has an owner, a workaround, and a customer communication plan.' 3
  publish "$oncall_token" 'Tomorrow 09:00 handoff prepared' 'Jon will review the 75k-run evidence and update the release command channel.' 4
  unset release_token customer_token oncall_token app_json
  touch "$seed_marker"
fi

unset GOTIFY_DEFAULTUSER_PASS
wait "$gotify_pid"
