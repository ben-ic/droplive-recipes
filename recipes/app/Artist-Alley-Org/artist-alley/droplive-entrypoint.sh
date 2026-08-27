#!/bin/sh
set -eu

: "${ARTIST_ALLEY_OWNER_PASSWORD:?DropLive must generate the owner password}"
: "${AA_SCRAMBLE_KEY:?DropLive must generate the password scramble key}"
: "${AA_MASTER_KEY:?DropLive must generate the at-rest master key}"
: "${AA_DB_HOST:?DropLive must attach managed PostgreSQL}"
: "${AA_DB_PASSWORD:?DropLive must attach managed PostgreSQL}"

seed_root=/tmp/droplive-artist-alley-seed
seed_marker=/var/lib/aa-storage/.droplive-emberlight-v1
cookie_jar=/tmp/droplive-artist-alley-cookie

mkdir -p /var/lib/aa-storage "$seed_root"
node /opt/droplive/generate-demo.mjs "$seed_root"

if [ ! -f "$seed_marker" ]; then
  # The upstream seed command owns schema migration, first-admin creation and
  # all relation writes. Its documented demo bootstrap is temporary: after the
  # server starts, this script changes that password to DropLive's generated
  # per-session owner value through the application's own authenticated API.
  AA_BOOTSTRAP_DEFAULT_ADMIN=1 /app/aa seed \
    --site "$seed_root/site" \
    --catalogue "$seed_root/catalogue" \
    --previews=true
fi

"$@" &
app_pid=$!
trap 'kill "$app_pid" 2>/dev/null || true; wait "$app_pid" 2>/dev/null || true' INT TERM EXIT

attempt=0
until curl -fsS http://127.0.0.1:8080/healthz >/dev/null; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 90 ]; then
    echo "artist-alley did not become healthy" >&2
    exit 1
  fi
  sleep 1
done

if [ ! -f "$seed_marker" ]; then
  login_code=$(curl -sS -o /tmp/droplive-login-response -w '%{http_code}' \
    -c "$cookie_jar" \
    -H 'Content-Type: application/json' \
    -d '{"username":"admin","password":"ArtistAlleyMogul"}' \
    http://127.0.0.1:8080/api/v1/auth/login)
  if [ "$login_code" != 200 ]; then
    echo "artist-alley owner bootstrap login failed with HTTP $login_code" >&2
    exit 1
  fi

  change_body=$(node -e 'process.stdout.write(JSON.stringify({current_password:"ArtistAlleyMogul",new_password:process.env.ARTIST_ALLEY_OWNER_PASSWORD,revoke_other_sessions:true}))')
  change_code=$(curl -sS -o /tmp/droplive-password-response -w '%{http_code}' \
    -b "$cookie_jar" \
    -X PUT \
    -H 'Content-Type: application/json' \
    --data "$change_body" \
    http://127.0.0.1:8080/api/v1/account/password)
  if [ "$change_code" != 200 ]; then
    echo "artist-alley owner password rotation failed with HTTP $change_code" >&2
    exit 1
  fi
  : > "$seed_marker"
fi

wait "$app_pid"
