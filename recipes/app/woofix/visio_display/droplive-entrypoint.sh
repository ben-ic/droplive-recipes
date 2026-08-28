#!/bin/sh
set -eu

: "${ADMIN_PASSWORD:?DropLive supplies the Northstar owner password}"
: "${SECRET_KEY:?DropLive supplies the Flask session key}"
: "${DISPLAY_API_TOKEN:?DropLive supplies the display token}"
: "${CLIENT_HEARTBEAT_TOKEN:?DropLive supplies the kiosk heartbeat token}"
: "${DATABASE_URL:?DropLive supplies the PostgreSQL companion}"
: "${REDIS_URL:?DropLive supplies the Redis companion}"

attempt=0
until python /usr/local/lib/seed-visio-demo.py; do
    attempt=$((attempt + 1))
    if [ "$attempt" -ge 30 ]; then
        echo "[droplive] Visio-Display seed did not complete; starting the app without it" >&2
        break
    fi
    sleep 2
done

exec "$@"
