#!/bin/sh
set -eu

seed_marker=/var/www/FreshRSS/data/.droplive-business-saas-company-v1-seeded
refresh_marker=/var/www/FreshRSS/data/.droplive-business-saas-company-v1-refreshed
if [ -n "${FRESHRSS_PASSWORD:-}" ] && [ -n "${DROPLIVE_FEED_URL:-}" ] && [ ! -f "$seed_marker" ]; then
  php /usr/local/lib/droplive-freshrss-create-user.php
  php /usr/local/lib/droplive-freshrss-import.php /tmp/droplive.opml
  php ./cli/import-for-user.php --user maya --filename /tmp/droplive.opml
  : >"$seed_marker"
fi

./cli/access-permissions.sh

# The RSS fixture becomes reachable only after the app and emulator have both
# started. A first fetch can therefore fail during normal launch. Do not make
# that short race prevent FreshRSS from serving its user interface.
if [ -n "${DROPLIVE_FEED_URL:-}" ] && [ ! -f "$refresh_marker" ]; then
  (
    attempts=0
    while [ "$attempts" -lt 12 ]; do
      if php ./cli/actualize-user.php --user maya; then
        : >"$refresh_marker"
        exit 0
      fi
      attempts=$((attempts + 1))
      sleep 5
    done
    exit 0
  ) &
fi

exec apache2ctl -D FOREGROUND
