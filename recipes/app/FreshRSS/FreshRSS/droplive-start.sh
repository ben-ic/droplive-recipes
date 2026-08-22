#!/bin/sh
set -eu

marker=/var/www/FreshRSS/data/.droplive-business-saas-company-v1
if [ -n "${FRESHRSS_PASSWORD:-}" ] && [ ! -f "$marker" ]; then
  php /usr/local/lib/droplive-freshrss-create-user.php
  php /usr/local/lib/droplive-freshrss-import.php /tmp/droplive.opml
  php ./cli/import-for-user.php --user maya --filename /tmp/droplive.opml
  php ./cli/actualize-user.php --user maya
  : >"$marker"
fi

./cli/access-permissions.sh

exec apache2ctl -D FOREGROUND
