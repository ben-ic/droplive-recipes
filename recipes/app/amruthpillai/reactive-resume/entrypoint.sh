#!/bin/sh
set -eu

# These guards declare the inputs. DropLive binds the public origin, the
# PostgreSQL companion URL, and the generated application secret.
: "${APP_URL:?DropLive supplies the public origin}"
: "${DATABASE_URL:?DropLive supplies the PostgreSQL companion URL}"
: "${AUTH_SECRET:?DropLive generates the authentication secret}"

exec docker-entrypoint.sh "$@"
