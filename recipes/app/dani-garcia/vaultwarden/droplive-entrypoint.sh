#!/bin/sh
# droplive: generate=hex96 ownership=app purpose=admin-bootstrap lifecycle=stable rotation=app name=DROPLIVE_ADMIN_TOKEN
set -eu

: "${DROPLIVE_PUBLIC_ORIGIN:?DropLive must derive the public HTTPS URL}"
: "${DROPLIVE_ADMIN_TOKEN:?DropLive must generate the Vaultwarden admin token}"

DOMAIN="$DROPLIVE_PUBLIC_ORIGIN"
export DOMAIN

case "$DROPLIVE_PUBLIC_ORIGIN" in
  https://*) ;;
  *)
    echo "[vaultwarden-init] DOMAIN must be the HTTPS public URL" >&2
    exit 64
    ;;
esac

# Vaultwarden's own generator produces the Argon2id PHC string required by the
# admin page. It needs a controlling terminal, so the official image's bundled
# util-linux `script` supplies a short-lived PTY. Only the PHC string is passed
# to the long-running server; the DropLive plaintext secret is removed first.
admin_token_hash="$(
  printf '%s\n%s\n' "$DROPLIVE_ADMIN_TOKEN" "$DROPLIVE_ADMIN_TOKEN" |
    script -q -c "/vaultwarden hash" /dev/null 2>/dev/null |
    tr -d '\r' |
    sed -n "s/^ADMIN_TOKEN='\(.*\)'$/\1/p" |
    tail -n 1
)"

case "$admin_token_hash" in
  '$argon2id$'*) ;;
  *)
    echo "[vaultwarden-init] official Argon2id admin-token generation failed" >&2
    exit 65
    ;;
esac

export ADMIN_TOKEN="$admin_token_hash"
unset admin_token_hash DROPLIVE_ADMIN_TOKEN

# SIGNUPS_ALLOWED remains enabled for the first owner claim. The owner must use
# the generated admin token at /admin immediately after creating their account
# and disable public signups; this is deliberately documented rather than hidden
# behind a background watcher that could race account creation.
exec "$@"
