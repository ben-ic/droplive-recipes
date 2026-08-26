#!/bin/sh
set -eu

mkdir -p /datastore
if [ ! -e /datastore/url-watches.json ]; then
  cp /usr/local/share/droplive-changedetection-datastore.json /datastore/url-watches.json
fi

# The current changedetection.io release migrates the legacy datastore before
# it creates a new changedetection.json.  Give that migration a per-session
# API token so the seed helper can use the protected API after startup.
python - <<'PY'
import json
import secrets

path = "/datastore/url-watches.json"
with open(path, encoding="utf-8") as source:
    data = json.load(source)

application = data.setdefault("settings", {}).setdefault("application", {})
application.setdefault("api_access_token_enabled", True)
application.setdefault("api_access_token", secrets.token_hex(16))

with open(path, "w", encoding="utf-8") as target:
    json.dump(data, target)
    target.write("\n")
PY

"$@" &
server_pid=$!
trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT

if [ -n "${DROPLIVE_COMPANY_URL:-}" ] && [ -n "${DROPLIVE_CHANGING_URL:-}" ]; then
  python /usr/local/lib/droplive-changedetection-seed.py
fi
wait "$server_pid"
