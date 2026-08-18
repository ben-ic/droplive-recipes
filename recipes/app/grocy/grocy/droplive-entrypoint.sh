#!/usr/bin/env bash
set -euo pipefail

# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=GROCY_ADMIN_PASSWORD capability=owner-login
: "${GROCY_ADMIN_PASSWORD:?DropLive must generate GROCY_ADMIN_PASSWORD}"

if [[ ${#GROCY_ADMIN_PASSWORD} -ne 16 || ${GROCY_ADMIN_PASSWORD} == *[^A-Za-z0-9_-]* ]]; then
    echo "GROCY_ADMIN_PASSWORD must contain exactly 16 URL-safe characters" >&2
    exit 1
fi

exec /init "$@"
