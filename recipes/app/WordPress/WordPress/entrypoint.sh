#!/bin/sh
set -eu

: "${DATABASE_URL:?DropLive supplies the MySQL connection URL}"
: "${WORDPRESS_ADMIN_PASSWORD:?DropLive generates the WordPress admin password}"

WORDPRESS_DB_HOST_VALUE="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo $u["host"] ?? "";')"
WORDPRESS_DB_PORT_VALUE="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo $u["port"] ?? "3306";')"
WORDPRESS_DB_USER_VALUE="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo rawurldecode($u["user"] ?? "");')"
WORDPRESS_DB_PASSWORD_VALUE="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo rawurldecode($u["pass"] ?? "");')"
WORDPRESS_DB_NAME_VALUE="$(php -r '$u=parse_url(getenv("DATABASE_URL")); echo rawurldecode(ltrim($u["path"] ?? "", "/"));')"
: "${WORDPRESS_DB_HOST_VALUE:?DropLive supplies the MySQL host}"
: "${WORDPRESS_DB_USER_VALUE:?DropLive supplies the MySQL user}"
: "${WORDPRESS_DB_PASSWORD_VALUE:?DropLive supplies the MySQL password}"
: "${WORDPRESS_DB_NAME_VALUE:?DropLive supplies the MySQL database}"

export WORDPRESS_DB_HOST="${WORDPRESS_DB_HOST_VALUE}:${WORDPRESS_DB_PORT_VALUE}"
export WORDPRESS_DB_USER="$WORDPRESS_DB_USER_VALUE"
export WORDPRESS_DB_PASSWORD="$WORDPRESS_DB_PASSWORD_VALUE"
export WORDPRESS_DB_NAME="$WORDPRESS_DB_NAME_VALUE"

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
WORDPRESS_PID=$!

stop_wordpress() {
  kill -TERM "$WORDPRESS_PID" 2>/dev/null || true
  wait "$WORDPRESS_PID" 2>/dev/null || true
}
trap stop_wordpress INT TERM EXIT

ATTEMPT=0
while [ "$ATTEMPT" -lt 120 ]; do
  if curl -fsSL http://127.0.0.1/wp-login.php | grep -q 'name="log"'; then
    trap - EXIT
    wait "$WORDPRESS_PID"
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

  ATTEMPT=$((ATTEMPT + 1))
  sleep 1
done

echo 'WordPress automatic installation did not complete within 120 seconds' >&2
exit 1
