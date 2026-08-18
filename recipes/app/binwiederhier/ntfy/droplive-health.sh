#!/bin/sh
set -eu

test -w /var/lib/ntfy
test -w /var/lib/ntfy/attachments
test -s /var/lib/ntfy/auth.db
test -s /var/lib/ntfy/cache.db
test -f /var/lib/ntfy/.droplive-initialized-v1

wget -qO- http://127.0.0.1:8080/v1/health |
  grep -Eq '"healthy"[[:space:]]*:[[:space:]]*true'
