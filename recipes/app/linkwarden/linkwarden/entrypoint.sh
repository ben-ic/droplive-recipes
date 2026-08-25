#!/bin/sh
set -eu

# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=NEXTAUTH_SECRET
: "${NEXTAUTH_SECRET:?DropLive must provide NEXTAUTH_SECRET at runtime}"
: "${NEXTAUTH_URL:?DropLive must provide NEXTAUTH_URL at runtime}"
: "${DATABASE_URL:?DropLive must provide DATABASE_URL from the managed PostgreSQL companion}"

# Linkwarden documents the NextAuth callback base as /api/v1/auth. DropLive's
# canonical public-origin binding is intentionally origin-shaped, so append the
# fixed upstream path at process start rather than baking a tenant URL into the
# image. Do not append twice when the caller already supplied it.
case "$NEXTAUTH_URL" in
  */api/v1/auth) : ;;
  */) NEXTAUTH_URL="${NEXTAUTH_URL}api/v1/auth" ;;
  *) NEXTAUTH_URL="${NEXTAUTH_URL}/api/v1/auth" ;;
esac
export NEXTAUTH_URL

# Migrations are part of Linkwarden's own command. Start that command first,
# then seed through the application's pinned Prisma client after its schema is
# ready. The seed is independent of the web process, so an RSS-style first-run
# timing race cannot prevent the login page from serving.
/usr/local/bin/docker-entrypoint.sh "$@" &
app_pid=$!

node /data/droplive-linkwarden-seed.cjs &
seed_pid=$!

stop() {
  kill "$seed_pid" "$app_pid" 2>/dev/null || true
  wait "$seed_pid" 2>/dev/null || true
  wait "$app_pid" 2>/dev/null || true
}
trap stop INT TERM

wait "$app_pid"
