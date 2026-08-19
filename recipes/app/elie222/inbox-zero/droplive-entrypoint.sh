#!/bin/sh
set -eu

# Map DropLive's platform bindings onto Inbox Zero's own names, then hand over to
# upstream's start script unchanged.
#
# Nothing is invented here. Every value either comes from the platform or is a
# static self-hosted flag; a missing one fails loudly at start rather than at the
# first request, because an app that boots with a blank secret fails deep inside
# its own error handling and reads as the app being broken.

: "${PUBLIC_URL:?DropLive must derive PUBLIC_URL from the assigned public HTTPS origin}"
: "${DATABASE_URL:?DropLive must derive DATABASE_URL from the postgres companion}"
: "${AUTH_SECRET:?DropLive must generate AUTH_SECRET}"
: "${EMAIL_ENCRYPT_SECRET:?DropLive must generate EMAIL_ENCRYPT_SECRET}"
: "${EMAIL_ENCRYPT_SALT:?DropLive must generate EMAIL_ENCRYPT_SALT}"
: "${INTERNAL_API_KEY:?DropLive must generate INTERNAL_API_KEY}"
: "${API_KEY_SALT:?DropLive must generate API_KEY_SALT}"

case "$PUBLIC_URL" in
  https://?*) ;;
  *)
    echo '[inbox-zero-init] PUBLIC_URL must be the assigned public HTTPS origin' >&2
    exit 64
    ;;
esac

# Prisma migrations use DIRECT_URL and the pooled client uses DATABASE_URL. The
# co-located companion is the same server for both, and pointing them at different
# things is how a migration runs against a database the app never reads.
export NEXT_PUBLIC_BASE_URL="${PUBLIC_URL%/}"
export INTERNAL_API_URL="${NEXT_PUBLIC_BASE_URL}"
export DIRECT_URL="${DIRECT_URL:-$DATABASE_URL}"

# The OAuth providers are the emulator, and the app's own *_BASE_URL switches are
# what point it there — no interception, no certificate, no hosts file.
#
# Client id and secret are not credentials here and must not look like them. The
# emulator accepts any client_id while no `oauth_clients` block is seeded, so these
# name the demo rather than authenticate it.
export GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-droplive-demo}"
export GOOGLE_CLIENT_SECRET="${GOOGLE_CLIENT_SECRET:-droplive-demo-secret}"
export MICROSOFT_CLIENT_ID="${MICROSOFT_CLIENT_ID:-droplive-demo}"
export MICROSOFT_CLIENT_SECRET="${MICROSOFT_CLIENT_SECRET:-droplive-demo-secret}"

# Required by the app's own schema (`apps/web/env.ts`: `z.string().min(1)`), read
# from the source rather than guessed — the app refuses to start without it even
# though a demo never uses Gmail push. It names a Cloud Pub/Sub topic that does not
# exist here and nothing subscribes to one: the value has to be present, not real.
export GOOGLE_PUBSUB_TOPIC_NAME="${GOOGLE_PUBSUB_TOPIC_NAME:-projects/droplive-demo/topics/none}"

# The LLM is the host's model fixture, reached through the app's own
# OpenAI-compatible provider. LLM_API_KEY authenticates nothing — the fixture
# ignores it — but the app refuses to start a provider with an empty key.
# Always set, not only when the platform supplied a base URL. The app validates
# its whole environment at boot and treats the LLM provider as required, so an
# unset key fails startup before anything can be demonstrated — including during a
# build probe, where no emulator exists yet. The default names the host fixture;
# nothing calls it during startup, so a probe that cannot resolve it still boots.
export OPENAI_COMPATIBLE_BASE_URL="${OPENAI_COMPATIBLE_BASE_URL:-http://model.emulator.winch.internal:15080/v1}"
export OPENAI_COMPATIBLE_MODEL="${OPENAI_COMPATIBLE_MODEL:-droplive-emulated}"
export DEFAULT_LLM_PROVIDER="${DEFAULT_LLM_PROVIDER:-openai-compatible}"
export DEFAULT_LLM_MODEL="${DEFAULT_LLM_MODEL:-$OPENAI_COMPATIBLE_MODEL}"
export LLM_API_KEY="${LLM_API_KEY:-emulated-no-key-required}"

# Upstash is a shim over the session's own Redis, so the app gets real semantics
# through the HTTP door its client insists on.
if [ -n "${UPSTASH_REDIS_URL:-}" ]; then
  export UPSTASH_REDIS_TOKEN="${UPSTASH_REDIS_TOKEN:-droplive-demo-token}"
fi

echo "[inbox-zero-init] origin=${NEXT_PUBLIC_BASE_URL} google=${GOOGLE_BASE_URL:-unset} llm=${OPENAI_COMPATIBLE_BASE_URL:-unset}"

exec docker-entrypoint.sh /app/docker/scripts/start.sh
