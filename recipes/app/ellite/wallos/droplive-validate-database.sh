#!/bin/sh
set -eu

mode=${1:-check}
db=/var/www/html/db/wallos.db
expected_signature=1b6e0719f76162bf5dbdac9f76f9944efe706d42f2e77998573101a2307753fd

fail() {
  echo "[wallos-db] $*" >&2
  exit 1
}

[ -f "$db" ] || fail 'wallos.db is missing'

legacy_exists=$(sqlite3 -readonly "$db" \
  "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='notifications';")
if [ "$legacy_exists" -eq 1 ]; then
  [ "$mode" = repair ] || fail 'obsolete notifications table remains after migration 000016'
  legacy_rows=$(sqlite3 -readonly "$db" 'SELECT COUNT(*) FROM notifications;')
  if [ "$legacy_rows" -gt 1 ]; then
    # Migration 000016 split one legacy row across two tables without retaining
    # a shared key. More than one row is therefore ambiguous: do not infer a
    # pairing and never drop the only authoritative legacy tuples.
    fail 'migration 000016 left multiple legacy notification rows; refusing ambiguous repair'
  fi
  if [ "$legacy_rows" -eq 1 ]; then
    email_rows=$(sqlite3 -readonly "$db" 'SELECT COUNT(*) FROM email_notifications;')
    settings_rows=$(sqlite3 -readonly "$db" 'SELECT COUNT(*) FROM notification_settings;')
    [ "$email_rows" -eq 1 ] && [ "$settings_rows" -eq 1 ] ||
      fail 'migration 000016 did not preserve an exact singleton notification pair'

    # Compare the complete legacy tuple against the one split email/settings
    # pair. SQLite IS is deliberately null-safe; no credential value is printed.
    preserved=$(sqlite3 -readonly "$db" '
      SELECT CASE WHEN
        n.enabled IS e.enabled AND
        n.smtp_address IS e.smtp_address AND
        n.smtp_port IS e.smtp_port AND
        n.smtp_username IS e.smtp_username AND
        n.smtp_password IS e.smtp_password AND
        n.from_email IS e.from_email AND
        n.encryption IS e.encryption AND
        n.days IS s.days
      THEN 1 ELSE 0 END
      FROM notifications AS n
      CROSS JOIN email_notifications AS e
      CROSS JOIN notification_settings AS s;
    ')
    if [ "$preserved" -ne 1 ]; then
      fail 'migration 000016 did not preserve the exact legacy notification tuple'
    fi
  fi
  timeout 30 sqlite3 -cmd '.timeout 5000' "$db" 'DROP TABLE notifications;'
  echo "[wallos-db] remediated upstream migration 000016 lock; preserved_rows=$legacy_rows"
fi

integrity=$(timeout 30 sqlite3 -cmd '.timeout 5000' -readonly "$db" 'PRAGMA integrity_check;')
[ "$integrity" = ok ] || fail "SQLite integrity check failed: $integrity"

foreign_key_errors=$(timeout 30 sqlite3 -cmd '.timeout 5000' -readonly "$db" 'PRAGMA foreign_key_check;')
[ -z "$foreign_key_errors" ] || fail "SQLite foreign-key check failed: $foreign_key_errors"

expected_migrations=$(
  find /var/www/html/migrations -maxdepth 1 -type f -name '*.php' -print |
    sed 's#.*/#migrations/#' |
    sort
)
actual_migrations=$(sqlite3 -readonly "$db" 'SELECT migration FROM migrations ORDER BY migration;')
[ "$actual_migrations" = "$expected_migrations" ] || fail 'recorded migrations do not exactly match the pinned release'

signature=$(
  for table in $(sqlite3 -readonly "$db" \
    "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;"); do
    sqlite3 -readonly -separator '|' "$db" "PRAGMA table_info('$table');" |
      sed "s#^#$table|#"
  done |
    sed -E 's#^(user\|14\|budget_period_anchor_date\|TEXT\|0\|).*#\1<install-date>|0#' |
    sha256sum |
    cut -d' ' -f1
)
[ "$signature" = "$expected_signature" ] || fail "schema signature mismatch: $signature"

if [ "$mode" = repair ]; then
  printf '%s\n' "$signature" >/run/wallos/database-validated
  chmod 0600 /run/wallos/database-validated
fi

[ "$mode" = quiet ] || echo '[wallos-db] migrations=52 integrity=ok foreign_keys=ok schema=verified'
