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

exec /usr/local/bin/docker-entrypoint.sh "$@"
