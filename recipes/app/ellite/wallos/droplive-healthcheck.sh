#!/bin/sh
set -eu

runtime_dir=/run/wallos
for name in php-fpm crond nginx; do
  pid=$(cat "$runtime_dir/$name.pid")
  kill -0 "$pid"
done

crontab -l | cmp -s - /usr/local/share/droplive-wallos-crontab

curl -fsS http://127.0.0.1/health.php | grep -qx 'OK'

test "$(cat "$runtime_dir/database-validated")" = \
  1b6e0719f76162bf5dbdac9f76f9944efe706d42f2e77998573101a2307753fd

timeout 5 sqlite3 -cmd '.timeout 3000' -readonly /var/www/html/db/wallos.db "
  SELECT CASE
    WHEN (SELECT COUNT(*) FROM migrations) = 52
     AND EXISTS (SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'user')
     AND EXISTS (SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'subscriptions')
    THEN 'OK' ELSE 'NOT_READY' END;
" | grep -qx 'OK'
