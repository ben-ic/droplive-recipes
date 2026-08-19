#!/bin/sh
# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=DAGU_AUTH_BUILTIN_INITIAL_ADMIN_PASSWORD capability=owner-login username=admin
set -eu

if test "$(id -u)" = 0; then
  mkdir -p /var/lib/dagu
  # Managed-volume restores can lose the numeric owner. Keep the repair
  # bounded to Dagu's one declared data root and to two minutes before
  # privileges are dropped. A very large or damaged restore fails closed.
  timeout --signal=TERM 120 chown -R dagu:dagu /var/lib/dagu
  chmod 0700 /var/lib/dagu
  exec setpriv --reuid=1000 --regid=1000 --init-groups \
    /usr/local/bin/droplive-entrypoint --drop-privileges-complete
fi

if test ! -r /var/lib/dagu || test ! -w /var/lib/dagu; then
  echo '[dagu-init] Managed data root is not readable and writable by UID 1000.' >&2
  exit 73
fi

if test "${1:-}" != --drop-privileges-complete; then
  echo '[dagu-init] Refusing to initialize without the bounded privilege-drop step.' >&2
  exit 64
fi

: "${DAGU_AUTH_BUILTIN_INITIAL_ADMIN_PASSWORD:?DropLive must generate the initial Dagu owner password}"

password_length=${#DAGU_AUTH_BUILTIN_INITIAL_ADMIN_PASSWORD}
password_charset=url-safe
test -z "$(printf '%s' "$DAGU_AUTH_BUILTIN_INITIAL_ADMIN_PASSWORD" | LC_ALL=C tr -d 'A-Za-z0-9_-')" || password_charset=other
if test "$password_length" -lt 16 || test "$password_charset" != url-safe; then
  echo "[dagu-init] Owner password shape rejected: observed_length=$password_length observed_charset=$password_charset required=16-or-more-url-safe." >&2
  exit 64
fi
unset password_length password_charset

mkdir -p /var/lib/dagu/dags
seed_marker=/var/lib/dagu/.droplive-starter-v1
if test ! -e "$seed_marker"; then
  if test ! -e /var/lib/dagu/dags/droplive-welcome.yaml; then
    cp /opt/droplive/starter.yaml /var/lib/dagu/dags/droplive-welcome.yaml
  fi
  # Record that first-volume initialization completed. If an owner later
  # deletes the starter DAG, restart/redeploy must respect that choice.
  : > "$seed_marker"
fi
unset seed_marker

echo '[dagu-runtime] Starting Dagu 2.7.5 all-in-one on port 8080 as UID 1000.'
exec dagu start-all
