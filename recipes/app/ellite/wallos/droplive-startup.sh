#!/bin/sh
set -eu

db_dir=/var/www/html/db
logo_dir=/var/www/html/images/uploads/logos
runtime_dir=/run/wallos

mkdir -p "$db_dir" "$logo_dir/avatars" "$runtime_dir"
if ! timeout 60 chown -R www-data:www-data "$db_dir" "$logo_dir"; then
  echo '[wallos-init] Managed-path ownership did not complete within 60 seconds.' >&2
  exit 1
fi
chmod 0755 "$db_dir" "$logo_dir" "$logo_dir/avatars"
chown root:www-data "$runtime_dir"
chmod 0750 "$runtime_dir"
: >"$runtime_dir/createdatabase.log"
: >"$runtime_dir/migrate.log"
chmod 0600 "$runtime_dir/createdatabase.log" "$runtime_dir/migrate.log"

# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=DROPLIVE_OWNER_SETUP_TOKEN capability=owner-login
: "${DROPLIVE_OWNER_SETUP_TOKEN:?DropLive must generate DROPLIVE_OWNER_SETUP_TOKEN}"
owner_setup_token=$DROPLIVE_OWNER_SETUP_TOKEN
if [ "${#owner_setup_token}" -lt 32 ]; then
  echo '[wallos-init] DROPLIVE_OWNER_SETUP_TOKEN must be a generated secret of at least 32 characters.' >&2
  exit 1
fi
printf '%s' "$owner_setup_token" | sha256sum | cut -d' ' -f1 \
  >"$runtime_dir/owner-setup.sha256"
chown root:www-data "$runtime_dir/owner-setup.sha256"
chmod 0640 "$runtime_dir/owner-setup.sha256"
unset owner_setup_token DROPLIVE_OWNER_SETUP_TOKEN

echo '[wallos-init] Creating or checking the SQLite database.'
if ! timeout 120 php /var/www/html/endpoints/cronjobs/createdatabase.php \
  >"$runtime_dir/createdatabase.log" 2>&1; then
  echo '[wallos-init] Database creation/check failed; sensitive output withheld.' >&2
  sed -E 's/^(Setup token for database restore:).*/\1 [REDACTED]/' \
    "$runtime_dir/createdatabase.log" >&2
  exit 1
fi
sed -E 's/^(Setup token for database restore:).*/\1 [REDACTED]/' \
  "$runtime_dir/createdatabase.log"
rm -f "$runtime_dir/createdatabase.log"

echo '[wallos-init] Applying idempotent database migrations.'
if ! timeout 120 php /var/www/html/endpoints/db/migrate.php \
  >"$runtime_dir/migrate.log" 2>&1; then
  echo '[wallos-init] Database migration command failed.' >&2
  cat "$runtime_dir/migrate.log" >&2
  exit 1
fi

known_lock='SQLite3::exec(): database table is locked in /var/www/html/migrations/000016.php on line 60'
if grep -E 'Warning:|Fatal error:|Notice:' "$runtime_dir/migrate.log" |
   grep -Fv "$known_lock" >"$runtime_dir/migrate-unexpected.log"; then
  echo '[wallos-init] Database migration emitted an unexpected diagnostic.' >&2
  cat "$runtime_dir/migrate-unexpected.log" >&2
  exit 1
fi
rm -f "$runtime_dir/migrate-unexpected.log"

if ! /usr/local/bin/droplive-validate-database.sh repair; then
  echo '[wallos-init] Database migration validation failed.' >&2
  cat "$runtime_dir/migrate.log" >&2
  exit 1
fi

echo '[wallos-init] Running required startup maintenance.'
for job in updatenextpayment updateexchange; do
  if ! /usr/local/bin/droplive-cron-run "$job" 120 none \
    /usr/local/bin/php "/var/www/html/endpoints/cronjobs/$job.php"; then
    echo "[wallos-init] Required startup maintenance failed: $job" >&2
    exit 1
  fi
done

if ! timeout 60 chown -R www-data:www-data "$db_dir" "$logo_dir"; then
  echo '[wallos-init] Final managed-path ownership did not complete within 60 seconds.' >&2
  exit 1
fi
/usr/bin/crontab /usr/local/share/droplive-wallos-crontab
crontab -l | cmp -s - /usr/local/share/droplive-wallos-crontab

shutdown_started=0
php_fpm_pid=
nginx_pid=
crond_pid=

shutdown_once() {
  [ "$shutdown_started" -eq 1 ] && return 0
  shutdown_started=1
  echo '[wallos-runtime] Graceful shutdown requested.'
  nginx -s quit 2>/dev/null || true
  [ -n "$php_fpm_pid" ] && kill -QUIT "$php_fpm_pid" 2>/dev/null || true
  [ -n "$crond_pid" ] && kill -TERM "$crond_pid" 2>/dev/null || true
}

trap 'shutdown_once' TERM INT QUIT

echo '[wallos-runtime] Starting PHP-FPM, cron, and Nginx.'
php-fpm -F &
php_fpm_pid=$!
crond -f -l 5 -L /dev/stdout &
crond_pid=$!
nginx -g 'daemon off;' &
nginx_pid=$!

printf '%s\n' "$php_fpm_pid" > "$runtime_dir/php-fpm.pid"
printf '%s\n' "$crond_pid" > "$runtime_dir/crond.pid"
printf '%s\n' "$nginx_pid" > "$runtime_dir/nginx.pid"

while kill -0 "$php_fpm_pid" "$crond_pid" "$nginx_pid" 2>/dev/null; do
  sleep 5 &
  wait $! || true
done

if [ "$shutdown_started" -eq 1 ]; then
  wait || true
  echo '[wallos-runtime] Graceful shutdown complete.'
  exit 0
fi

echo '[wallos-runtime] A required child process exited.' >&2
shutdown_once
wait || true
exit 1
