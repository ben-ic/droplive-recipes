#!/bin/sh
set -eu

: "${DATABASE_URL:?DropLive supplies the MySQL connection URL}"
: "${WORDPRESS_ADMIN_PASSWORD:?DropLive generates the WordPress admin password}"

export WORDPRESS_DB_HOST="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo $u["host"] ?? "";'):$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo $u["port"] ?? "3306";')"
export WORDPRESS_DB_USER="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo rawurldecode($u["user"] ?? "");')"
export WORDPRESS_DB_PASSWORD="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo rawurldecode($u["pass"] ?? "");')"
export WORDPRESS_DB_NAME="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo rawurldecode(ltrim($u["path"] ?? "", "/"));')"

# The build probe can create wp-config.php with its temporary companion host.
# Recreate it from the runtime DATABASE_URL before the app starts.
rm -f /var/www/html/wp-config.php

# WordPress otherwise stores the loopback address used by this setup script.
# Use the public request host so login and admin redirects stay on the demo URL.
export WORDPRESS_CONFIG_EXTRA='
if (isset($_SERVER["HTTP_HOST"])) {
    $forwarded_proto = isset($_SERVER["HTTP_X_FORWARDED_PROTO"]) ? $_SERVER["HTTP_X_FORWARDED_PROTO"] : "http";
    $public_url = $forwarded_proto . "://" . $_SERVER["HTTP_HOST"];
    define("WP_HOME", $public_url);
    define("WP_SITEURL", $public_url);
}
'

docker-entrypoint.sh "$@" &
trap 'kill 0 2>/dev/null || true' INT TERM EXIT

while :; do
  if curl -fsSL http://127.0.0.1/wp-login.php | grep -q 'name="log"'; then
    trap - EXIT
    wait
    exit 0
  fi

  if curl -fsS 'http://127.0.0.1/wp-admin/install.php?step=1' | grep -q 'weblog_title'; then
    curl -fsS -o /dev/null \
      --data-urlencode 'weblog_title=DropLive Demo' \
      --data-urlencode 'user_name=admin' \
      --data-urlencode "admin_password=${WORDPRESS_ADMIN_PASSWORD}" \
      --data-urlencode "admin_password2=${WORDPRESS_ADMIN_PASSWORD}" \
      --data-urlencode 'admin_email=demo@example.invalid' \
      --data-urlencode 'blog_public=0' \
      --data-urlencode 'Submit=Install WordPress' \
      'http://127.0.0.1/wp-admin/install.php?step=2' || true
  fi

  sleep 1
done
