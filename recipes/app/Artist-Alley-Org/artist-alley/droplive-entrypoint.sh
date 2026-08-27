#!/bin/sh
set -eu

: "${ARTIST_ALLEY_OWNER_PASSWORD:?DropLive must generate the owner password}"
: "${AA_SCRAMBLE_KEY:?DropLive must generate the password scramble key}"
: "${ARTIST_ALLEY_MASTER_KEY_HEX:?DropLive must generate the at-rest master key}"
: "${AA_DB_HOST:?DropLive must attach managed PostgreSQL}"
: "${AA_DB_PASSWORD:?DropLive must attach managed PostgreSQL}"

seed_root=/opt/artist-alley-seed
seed_marker=/var/lib/aa-storage/.droplive-official-kaggle-v7
cookie_jar=/tmp/droplive-artist-alley-cookie
feed_response=/tmp/droplive-artist-alley-feed
me_response=/tmp/droplive-artist-alley-me
seed_log=/tmp/droplive-artist-alley-seed.log
internal_url=http://127.0.0.1:8081
proxy_pid=

mkdir -p /var/lib/aa-storage

# Artist Alley requires standard Base64 for exactly 32 key bytes. DropLive
# generates the unambiguous 64-character hex form; convert it inside the guest
# so no padding or decoded-length assumption crosses the recipe boundary.
AA_MASTER_KEY=$(node -e 'process.stdout.write(Buffer.from(process.env.ARTIST_ALLEY_MASTER_KEY_HEX, "hex").toString("base64"))')
export AA_MASTER_KEY

if [ ! -f "$seed_marker" ]; then
  # The upstream seed command owns schema migration, first-admin creation and
  # all relation writes. Its documented demo bootstrap is temporary: after the
  # server starts, this script changes that password to DropLive's generated
  # per-session owner value through the application's own authenticated API.
  if ! AA_BOOTSTRAP_DEFAULT_ADMIN=1 /app/aa seed \
      --site "$seed_root/site" \
      --catalogue "$seed_root/catalogue" \
      --previews=true >"$seed_log" 2>&1; then
    tail -n 40 "$seed_log" >&2
    exit 1
  fi
  cat "$seed_log"
fi

"$@" &
app_pid=$!

cleanup() {
  trap - INT TERM EXIT
  if [ -n "$proxy_pid" ]; then
    kill "$proxy_pid" 2>/dev/null || true
    wait "$proxy_pid" 2>/dev/null || true
  fi
  kill "$app_pid" 2>/dev/null || true
  wait "$app_pid" 2>/dev/null || true
}
trap cleanup INT TERM EXIT

attempt=0
until curl -fsS "$internal_url/healthz" >/dev/null; do
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
    "$internal_url/api/v1/auth/login")
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
    "$internal_url/api/v1/account/password")
  if [ "$change_code" != 200 ]; then
    echo "artist-alley owner password rotation failed with HTTP $change_code" >&2
    exit 1
  fi
  : > "$seed_marker"
fi

# Always create a fresh authenticated session for the readiness check. The
# bootstrap cookie can be revoked by password rotation, and a restarted guest
# already has the marker and therefore never uses the bootstrap password.
login_body=$(node -e 'process.stdout.write(JSON.stringify({username:"admin",password:process.env.ARTIST_ALLEY_OWNER_PASSWORD}))')
login_code=$(curl -sS -o /tmp/droplive-owner-login-response -w '%{http_code}' \
  -c "$cookie_jar" \
  -H 'Content-Type: application/json' \
  --data "$login_body" \
  "$internal_url/api/v1/auth/login")
if [ "$login_code" != 200 ]; then
  echo "artist-alley generated owner login failed with HTTP $login_code" >&2
  exit 1
fi

# Use the exact session that the application returned. This also makes the
# authentication proof independent of curl's cookie-file policy for localhost.
owner_session=$(awk '$6 == "user" { value = $7 } END { print value }' "$cookie_jar")
if [ -z "$owner_session" ]; then
  echo "artist-alley generated owner login did not return a session cookie" >&2
  exit 1
fi
if ! curl -fsS -b "user=$owner_session" -o "$me_response" \
    "$internal_url/api/v1/auth/me" \
    || ! node -e '
      const fs = require("node:fs");
      const me = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
      if (me.username !== "admin") process.exit(1);
    ' "$me_response"; then
  echo "artist-alley generated owner session could not authenticate" >&2
  exit 1
fi

# The upstream seed command queues previews but does not render them. Its worker
# pool starts with the private server above. Do not expose the public port until
# the first 36-post feed has at least 24 real, servable cover previews. This is
# the smallest useful screen-sized cohort: the launch page cannot pass while
# the main feed is still a wall of fallback cards.
attempt=0
until curl -fsS -b "user=$owner_session" \
    -o "$feed_response" \
    "$internal_url/api/v1/posts?limit=36&feed=latest&dir=desc" \
    && node /usr/local/lib/droplive-feed-ready.mjs "$feed_response"; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 60 ]; then
    echo "artist-alley seed summary at readiness timeout:" >&2
    if [ -f "$seed_log" ]; then
      tail -n 30 "$seed_log" >&2
    else
      echo "seed was already complete before this process started" >&2
    fi
    echo "artist-alley authenticated session summary:" >&2
    node -e '
      const fs = require("node:fs");
      const me = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
      console.error(JSON.stringify({
        username: me.username,
        capabilities: me.capabilities,
        capabilities_status: me.capabilities_status,
      }));
    ' "$me_response"
    echo "artist-alley first feed response:" >&2
    cat "$feed_response" >&2
    echo "artist-alley first feed did not produce 24 cover previews" >&2
    exit 1
  fi
  sleep 5
done

# A raw TCP forwarder keeps HTTP streaming and WebSocket upgrades intact. Port
# 8080 does not exist before this point, so DropLive's /healthz probe is also a
# visual-readiness gate without changing Artist Alley itself.
node /usr/local/lib/droplive-tcp-proxy.mjs &
proxy_pid=$!
wait "$proxy_pid"
