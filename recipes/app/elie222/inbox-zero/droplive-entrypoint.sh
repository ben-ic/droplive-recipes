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

exec docker-entrypoint.sh "$@"
