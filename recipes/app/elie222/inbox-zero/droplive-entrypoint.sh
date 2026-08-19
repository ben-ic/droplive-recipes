#!/bin/sh
set -eu

# Initialize the writable .next mount, then hand over to the image's own entrypoint.
#
# The application rewrites its own build output at startup: `start.sh` substitutes
# every NEXT_PUBLIC_* placeholder into the already-built bundles, so `.next/server`
# and `.next/static` must be writable. Those values are per-session and cannot be
# baked at build time.
#
# A read-only root filesystem therefore needs `.next` on a writable mount, and a
# DropLive volume STARTS EMPTY. Docker's copy-up would hide that locally — it seeds a
# named volume from the image on first mount — so the recipe does the initialization
# itself and the Compose file sets `nocopy: true` to make the local test match.
#
# The template is the build output, moved aside at image build time.
TEMPLATE=/opt/droplive-next
TARGET=/app/apps/web/.next

if [ ! -d "$TEMPLATE" ]; then
  echo "[droplive-init] missing build template at $TEMPLATE" >&2
  exit 1
fi

# Empty means uninitialized. A restart onto a populated volume must not re-copy: the
# placeholders in it have already been substituted, and copying the template back
# would be harmless but slow, while copying over a running app would not.
if [ -z "$(ls -A "$TARGET" 2>/dev/null || true)" ]; then
  echo "[droplive-init] initializing $TARGET from $TEMPLATE"
  cp -a "$TEMPLATE/." "$TARGET/"
else
  echo "[droplive-init] $TARGET already initialized"
fi

# DEFAULT_LLMS is the application's own required form: an ordered provider:model
# chain. Its model half is not a value DropLive can name -- it is one DropLive
# supplies and this line composes. A plan binding names a SOURCE, so Compose asking
# for "openai-compatible:${OPENAI_COMPATIBLE_MODEL}" asks the platform to express a
# template it has no way to represent, and the recipe was refused for it.
#
# Deriving it here keeps the modern form the application prefers while leaving the
# platform to bind only what it can name. `:?` so a missing binding still fails
# loudly rather than composing a chain with an empty model.
: "${OPENAI_COMPATIBLE_MODEL:?DropLive must supply the emulated model name}"
export DEFAULT_LLMS="${DEFAULT_LLMS:-openai-compatible:${OPENAI_COMPATIBLE_MODEL}}"

exec docker-entrypoint.sh "$@"
