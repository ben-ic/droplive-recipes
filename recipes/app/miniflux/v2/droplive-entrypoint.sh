#!/bin/sh
set -eu

# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=ADMIN_PASSWORD capability=owner-login username=admin
: "${ADMIN_PASSWORD:?DropLive must generate the initial owner password}"
: "${DATABASE_URL:?DropLive must attach managed PostgreSQL}"
: "${BASE_URL:?DropLive must set the public application URL}"

exec "$@"
