#!/bin/sh
set -eu

: "${WORDPRESS_DB_HOST:?DropLive supplies the MySQL host}"
: "${WORDPRESS_DB_USER:?DropLive supplies the MySQL user}"
: "${WORDPRESS_DB_PASSWORD:?DropLive supplies the MySQL password}"
: "${WORDPRESS_DB_NAME:?DropLive supplies the MySQL database}"
: "${WORDPRESS_ADMIN_PASSWORD:?DropLive generates the WordPress admin password}"

# WordPress otherwise stores the loopback address used by this setup script.
# Use the public request host so login and admin redirects stay on the demo URL.
WORDPRESS_CONFIG_EXTRA='
if (isset($_SERVER["HTTP_HOST"])) {
    $forwarded_proto = isset($_SERVER["HTTP_X_FORWARDED_PROTO"]) ? $_SERVER["HTTP_X_FORWARDED_PROTO"] : "http";
    $public_url = $forwarded_proto . "://" . $_SERVER["HTTP_HOST"];
    define("WP_HOME", $public_url);
    define("WP_SITEURL", $public_url);
}
'
export WORDPRESS_CONFIG_EXTRA

docker-entrypoint.sh "$@" &
wordpress_pid=$!

stop_wordpress() {
  kill -TERM "$wordpress_pid" 2>/dev/null || true
  wait "$wordpress_pid" 2>/dev/null || true
}
trap stop_wordpress INT TERM EXIT

attempt=0
while [ "$attempt" -lt 120 ]; do
  if curl -fsSL http://127.0.0.1/wp-login.php | grep -q 'name="log"'; then
    trap - EXIT
    wait "$wordpress_pid"
    exit $?
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

  attempt=$((attempt + 1))
  sleep 1
done

echo 'WordPress automatic installation did not complete within 120 seconds' >&2
exit 1
