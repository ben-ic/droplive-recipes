#!/app/busybox sh
set -eu

# This credential belongs only to Wakapi's first-owner bootstrap. Wakapi lets
# the owner rotate it later, so DropLive must retain but never reapply it.
# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=WAKAPI_ADMIN_PASSWORD capability=owner-login username=admin
: "${WAKAPI_ADMIN_PASSWORD:?DropLive must generate WAKAPI_ADMIN_PASSWORD}"
: "${WAKAPI_PUBLIC_URL:?DropLive must generate WAKAPI_PUBLIC_URL}"

bb=/app/busybox
data_root=/data
database=${WAKAPI_DB_NAME:-/data/wakapi.db}
marker="$data_root/.droplive-owner-initialized"

case "$database" in
  "$data_root"/*) ;;
  *)
    printf '%s\n' 'Wakapi SQLite database must be inside /data' >&2
    exit 64
    ;;
esac

# Wakapi always initializes WebAuthn, even with registration disabled, and takes
# the relying-party id from WAKAPI_PUBLIC_URL's host. go-webauthn rejects a host
# that is not a domain, and Wakapi treats that as fatal. Check the assigned
# origin here so a wrong binding fails immediately and legibly instead of as an
# opaque WebAuthn fatal after the bootstrap health timeout.
public_url=${WAKAPI_PUBLIC_URL%/}
case "$public_url" in
  https://?*|http://?*) ;;
  *)
    printf '%s\n' 'WAKAPI_PUBLIC_URL must be the assigned public origin, with scheme' >&2
    exit 64
    ;;
esac

rp_host=${public_url#*://}
rp_host=${rp_host%%/*}
rp_host=${rp_host%%:*}
invalid=$(printf '%s' "$rp_host" | "$bb" tr -d 'A-Za-z0-9.-')
if [ -n "$invalid" ]; then
  printf '%s\n' 'WAKAPI_PUBLIC_URL host contains unsupported characters' >&2
  exit 64
fi
# The same rule go-webauthn applies to the relying-party id.
case "$rp_host" in
  localhost|*.*) ;;
  *)
    printf '%s\n' 'WAKAPI_PUBLIC_URL host must be a domain (WebAuthn relying-party id)' >&2
    exit 64
    ;;
esac
export WAKAPI_PUBLIC_URL="$public_url"

# Derive two stable, domain-separated application secrets from the retained
# bootstrap secret. The cookie-key value is valid base64 text and decodes to
# 48 bytes; the password pepper is a separate 256-bit hexadecimal value.
salt_record=$(printf 'droplive-wakapi-password-salt\000%s' "$WAKAPI_ADMIN_PASSWORD" | "$bb" sha256sum)
cookie_record=$(printf 'droplive-wakapi-cookie-key\000%s' "$WAKAPI_ADMIN_PASSWORD" | "$bb" sha256sum)
export WAKAPI_PASSWORD_SALT=${salt_record%% *}
export WAKAPI_COOKIE_KEY=${cookie_record%% *}

if [ -f "$marker" ]; then
  if [ ! -s "$database" ]; then
    printf '%s\n' 'Wakapi initialization marker exists but database is missing or empty' >&2
    exit 65
  fi
  unset WAKAPI_ADMIN_PASSWORD
  exec /app/wakapi
fi

export WAKAPI_LISTEN_IPV4=127.0.0.1
export WAKAPI_ALLOW_SIGNUP=true
export WAKAPI_INSECURE_COOKIES=true
bootstrap_log=/tmp/wakapi-bootstrap.log
"$bb" env -u WAKAPI_ADMIN_PASSWORD /app/wakapi >"$bootstrap_log" 2>&1 &
bootstrap_pid=$!

cleanup() {
  kill -TERM "$bootstrap_pid" 2>/dev/null || true
  attempts=0
  while kill -0 "$bootstrap_pid" 2>/dev/null; do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 10 ]; then
      printf '%s\n' 'Wakapi bootstrap did not stop after 10 seconds; killing it' >&2
      kill -KILL "$bootstrap_pid" 2>/dev/null || true
      break
    fi
    "$bb" sleep 1
  done
  wait "$bootstrap_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

ready=false
attempts=0
while [ "$attempts" -lt 60 ]; do
  if "$bb" wget -q -T 3 -O /dev/null http://127.0.0.1:3000/api/health; then
    ready=true
    break
  fi
  attempts=$((attempts + 1))
  "$bb" sleep 1
done
if [ "$ready" != true ]; then
  printf '%s\n' 'Timed out waiting for Wakapi bootstrap health' >&2
  "$bb" sed -n '1,160p' "$bootstrap_log" >&2
  exit 1
fi

umask 077
signup_form=/tmp/wakapi-signup.form
login_form=/tmp/wakapi-login.form
signup_headers=/tmp/wakapi-signup.headers
login_headers=/tmp/wakapi-login.headers
printf 'username=admin&email=&password=%s&password_repeat=%s' \
  "$WAKAPI_ADMIN_PASSWORD" "$WAKAPI_ADMIN_PASSWORD" >"$signup_form"
printf 'username=admin&password=%s' "$WAKAPI_ADMIN_PASSWORD" >"$login_form"

# Signup may report a conflict after an interrupted first boot. The following
# authenticated HTTP 302 is authoritative and makes recovery idempotent.
# BusyBox wget preserves POST on redirects, so the followed request receives
# 405; the exact first-response status is intentionally checked instead.
"$bb" wget -S -T 10 --post-file "$signup_form" -O /dev/null \
  -o "$signup_headers" http://127.0.0.1:3000/signup || true
"$bb" wget -S -T 10 --post-file "$login_form" -O /dev/null \
  -o "$login_headers" http://127.0.0.1:3000/login || true
if ! "$bb" grep -q 'HTTP/1.1 302 Found' "$login_headers"; then
  printf '%s\n' 'Wakapi first-owner login verification failed' >&2
  "$bb" sed -n '1,160p' "$bootstrap_log" >&2
  exit 1
fi

"$bb" rm -f "$signup_form" "$login_form" "$signup_headers" "$login_headers"
"$bb" touch "$marker"

cleanup
trap - EXIT INT TERM

unset WAKAPI_ADMIN_PASSWORD
export WAKAPI_LISTEN_IPV4=0.0.0.0
export WAKAPI_ALLOW_SIGNUP=false
export WAKAPI_INSECURE_COOKIES=false
exec /app/wakapi
