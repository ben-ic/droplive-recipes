#!/bin/sh
set -eu

# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=NTFY_ADMIN_PASSWORD capability=owner-login
: "${NTFY_ADMIN_PASSWORD:?DropLive must generate NTFY_ADMIN_PASSWORD}"
: "${NTFY_BASE_URL:?DropLive must derive NTFY_BASE_URL from the public origin}"

password_length=${#NTFY_ADMIN_PASSWORD}
password_charset=url-safe
test -z "$(printf '%s' "$NTFY_ADMIN_PASSWORD" | LC_ALL=C tr -d 'A-Za-z0-9_-')" || password_charset=other
if test "$password_length" -ne 16 || test "$password_charset" != url-safe; then
  echo "[ntfy-init] NTFY_ADMIN_PASSWORD shape rejected: observed_length=$password_length observed_charset=$password_charset required=16-url-safe." >&2
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

data_dir=/var/lib/ntfy
auth_file=$data_dir/auth.db
marker=$data_dir/.droplive-initialized-v1
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
unset NTFY_ADMIN_PASSWORD

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
