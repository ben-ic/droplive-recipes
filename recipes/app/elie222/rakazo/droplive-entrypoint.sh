#!/bin/sh
set -eu

: "${APP_URL:?DropLive supplies the public application URL}"
: "${DATABASE_URL:?DropLive supplies PostgreSQL}"
: "${BETTER_AUTH_SECRET:?DropLive generates the authentication secret}"
: "${ENCRYPTION_KEY:?DropLive generates the encryption key}"
: "${DAYTONA_API_URL:?DropLive supplies the local computer API URL}"
: "${DAYTONA_API_KEY:?DropLive supplies the local computer API key}"
: "${DAYTONA_TARGET:?DropLive supplies the local computer target}"
: "${OPENROUTER_BASE_URL:?DropLive supplies the reviewed model API URL}"
: "${OPENROUTER_API_KEY:?DropLive supplies the model API key}"

export BETTER_AUTH_URL="$APP_URL"
export WEB_ORIGIN="$APP_URL"
export API_URL="http://127.0.0.1:3100"
export API_PROXY_TARGET="http://127.0.0.1:3100"
export RAKAZO_HOST="$(node -e 'process.stdout.write(new URL(process.env.APP_URL).hostname)')"

pnpm --filter @rakazo/db exec prisma migrate deploy

cleanup() {
  trap - TERM INT EXIT
  kill -TERM "$api_pid" "$worker_pid" "$web_pid" 2>/dev/null || true
  wait "$api_pid" "$worker_pid" "$web_pid" 2>/dev/null || true
}

pnpm --filter @rakazo/api start &
api_pid=$!

i=0
until node -e "fetch('http://127.0.0.1:3100/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"
do
  i=$((i + 1))
  if [ "$i" -ge 60 ]; then
    echo "Rakazo API did not become ready" >&2
    kill -TERM "$api_pid" 2>/dev/null || true
    wait "$api_pid" 2>/dev/null || true
    exit 1
  fi
  sleep 1
done

pnpm --filter @rakazo/worker start &
worker_pid=$!
pnpm --filter @rakazo/web preview --host 0.0.0.0 --port 5173 &
web_pid=$!

trap cleanup TERM INT EXIT

while kill -0 "$api_pid" 2>/dev/null \
  && kill -0 "$worker_pid" 2>/dev/null \
  && kill -0 "$web_pid" 2>/dev/null
do
  sleep 1
done

echo "A Rakazo process exited unexpectedly" >&2
exit 1
