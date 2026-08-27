#!/bin/sh
set -eu

# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=NTFY_ADMIN_PASSWORD capability=owner-login username=admin
: "${NTFY_ADMIN_PASSWORD:?DropLive must generate NTFY_ADMIN_PASSWORD}"
: "${NTFY_BASE_URL:?DropLive must derive NTFY_BASE_URL from the public origin}"

password_length=${#NTFY_ADMIN_PASSWORD}
password_charset=url-safe
test -z "$(printf '%s' "$NTFY_ADMIN_PASSWORD" | LC_ALL=C tr -d 'A-Za-z0-9_-')" || password_charset=other
if test "$password_length" -lt 16 || test "$password_charset" != url-safe; then
  echo "[ntfy-init] NTFY_ADMIN_PASSWORD shape rejected: observed_length=$password_length observed_charset=$password_charset required=16-or-more-url-safe." >&2
  exit 64
fi
unset password_length password_charset
case "$NTFY_BASE_URL" in
  http://*|https://*) ;;
  *)
    echo '[ntfy-init] NTFY_BASE_URL must be an absolute HTTP(S) origin.' >&2
    exit 64
    ;;
esac
# DropLive may include the declared first screen in the origin value. ntfy's
# base-url is different: it must be the host origin, not a topic path.
NTFY_BASE_URL=$(printf '%s' "$NTFY_BASE_URL" | sed -E 's#^(https?://[^/]+).*$#\1#')
export NTFY_BASE_URL

data_dir=/var/lib/ntfy
auth_file=$data_dir/auth.db
marker=$data_dir/.droplive-initialized-v1
seed_marker=$data_dir/.droplive-company-seed-v1
runtime_dir=/run/ntfy
users_file=$runtime_dir/users.txt

mkdir -p "$data_dir/attachments" "$runtime_dir"
chmod 0700 "$data_dir" "$data_dir/attachments" "$runtime_dir"

if ! test -e "$auth_file"; then
  : >"$auth_file"
  chmod 0600 "$auth_file"
fi

inspect_users() {
  rm -f "$users_file"
  /usr/bin/ntfy user list >"$users_file"
  admin_count=$(grep -Ec '^user .+ \(role: admin,' "$users_file" || true)
  named_count=$(grep -Ec '^user [^*].* \(role:' "$users_file" || true)
  rm -f "$users_file"
}

inspect_users
if ! test -f "$marker"; then
  if test "$admin_count" -eq 0; then
    if test "$named_count" -ne 0; then
      echo '[ntfy-init] Existing auth database has users but no administrator; refusing unsafe bootstrap.' >&2
      exit 65
    fi
    echo '[ntfy-init] Creating the private-instance administrator.'
    NTFY_PASSWORD="$NTFY_ADMIN_PASSWORD" \
      /usr/bin/ntfy user add --role=admin admin >/dev/null
    inspect_users
  fi
  if test "$admin_count" -lt 1; then
    echo '[ntfy-init] Administrator bootstrap did not produce an admin account.' >&2
    exit 65
  fi
  touch "$marker"
  chmod 0600 "$marker"
fi

inspect_users
if test "$admin_count" -lt 1; then
  echo '[ntfy-init] Persistent auth database has no administrator.' >&2
  exit 65
fi

test -w "$data_dir"
test -w "$data_dir/attachments"

echo '[ntfy-runtime] Starting the official ntfy process on port 8080.'
shutdown_started=0
ntfy_pid=

shutdown_once() {
  test "$shutdown_started" -eq 1 && return 0
  shutdown_started=1
  echo '[ntfy-runtime] Graceful shutdown requested.'
  test -n "$ntfy_pid" && kill -TERM "$ntfy_pid" 2>/dev/null || true
}

trap 'shutdown_once' TERM INT QUIT
trap 'test -n "$ntfy_pid" && kill -HUP "$ntfy_pid" 2>/dev/null || true' HUP

/usr/bin/ntfy serve &
ntfy_pid=$!

if ! test -f "$seed_marker"; then
  publish() {
    /usr/bin/ntfy publish --user "admin:$NTFY_ADMIN_PASSWORD" \
      --title "$2" --tags "$3" --priority "$4" "http://127.0.0.1:8080/$1" "$5"
  }
  seed_ready=0
  # A cold µVM can take longer than the old 30-second publish retry window to
  # start the official server. Wait for the declared health response first, but
  # keep a hard bound so a broken server still fails the build.
  for attempt in $(seq 1 90); do
    if wget -qO- http://127.0.0.1:8080/v1/health 2>/dev/null |
      grep -Eq '"healthy"[[:space:]]*:[[:space:]]*true'; then
      if publish northstar-release 'Release 2.8 review starts' 'rocket,clipboard' 5 'Maya owns the review. Confirm cancellation coverage and customer communication before approval.'; then
        seed_ready=1
        break
      fi
    fi
    sleep 1
  done
  if test "$seed_ready" -ne 1; then
    echo '[ntfy-init] Could not publish the initial company notification.' >&2
    exit 65
  fi
  publish northstar-release 'Cancellation coverage complete' 'white_check_mark,test_tube' 4 'The 50k and 75k cancellation fixtures release worker leases and partial objects.'
  publish northstar-release 'Release notes need product approval' 'memo,eyes' 4 'Elena updated the audit-history notes. One product review remains before the release decision.'
  publish northstar-customers 'Lumen renewal is active' 'handshake,receipt' 5 'Invoice 4471 is open, due 30 August, and not overdue. Keep it separate from the export incident.'
  publish northstar-customers 'Three customer interviews ready' 'memo,people_hugging' 4 'Priya, Asha, and Diego feedback is tagged for the release review.'
  publish northstar-customers 'Harbor Mobility needs risk review' 'warning,bar_chart' 5 'The 75k scheduled export requires the tested timeout path before the 12 September renewal.'
  publish northstar-customers 'Ember Commerce follow-up' 'speech_balloon,calendar' 3 'Confirm the CSV header fix with the customer-success owner before Friday.'
  publish northstar-oncall 'Scheduled export latency elevated' 'rotating_light,chart_with_upwards_trend' 5 'Two scheduled jobs crossed the legacy-worker warning threshold. Interactive retries remain healthy.'
  publish northstar-oncall 'Lease cleanup confirmed' 'white_check_mark,wrench' 3 'The cancellation fixture released all test leases. Monitor the next scheduled run.'
  publish northstar-oncall 'No paging action required' 'information_source,shield' 2 'The export incident has an owner, workaround, and scheduled customer update.'
  publish northstar-oncall 'Morning handoff prepared' 'sunrise,clipboard' 3 'Jon will review the 75k evidence at 09:00 and update the release command topic.'
  touch "$seed_marker"
  chmod 0600 "$seed_marker"
fi

unset NTFY_ADMIN_PASSWORD
set +e
wait "$ntfy_pid"
ntfy_status=$?
set -e

if test "$shutdown_started" -eq 1; then
  wait "$ntfy_pid" 2>/dev/null || true
  echo '[ntfy-runtime] Graceful shutdown complete.'
  exit 0
fi

test "$ntfy_status" -ne 0 || ntfy_status=1
echo "[ntfy-runtime] Required ntfy process exited unexpectedly: status=$ntfy_status" >&2
exit "$ntfy_status"
