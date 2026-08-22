#!/bin/sh
set -eu

: "${BASE_URL:?DropLive supplies the public origin}"
: "${REDIS_URL:?DropLive supplies the Redis companion URL}"

export NODE_ENV=production
export UPLOAD_RATE_LIMIT_STORE=redis
export UPLOAD_RATE_LIMIT_REDIS_URL="$REDIS_URL"

exec "$@"
