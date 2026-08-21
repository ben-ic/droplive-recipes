#!/bin/sh
set -eu

: "${CALIBRE_ADMIN_PASSWORD:?DropLive generates the Calibre-Web admin password}"

mkdir -p /books
if [ ! -f /books/metadata.db ]; then
  cp /opt/droplive/calibre-library/metadata.db /books/metadata.db
fi
chown abc:abc /books/metadata.db
chmod 664 /books/metadata.db

sqlite3 /config/app.db \
  "UPDATE settings
     SET config_calibre_dir = '/books', config_password_policy = 0
   WHERE id = 1;"

python3 /app/calibre-web/cps.py \
  -p /config/app.db \
  -s "admin:${CALIBRE_ADMIN_PASSWORD}"
