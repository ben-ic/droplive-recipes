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

# MOVED, not copied, and a MARKER decides whether it has been done.
#
# A copy needs the build output twice over at once, and the writable filesystem is
# sized to the image plus a margin -- so the copy ran the device out of space
# partway through:
#
#   cp: can't create directory '/app/apps/web/.next/./server/app/_not-found':
#       No space left on device
#
# A rename inside one filesystem costs nothing and needs no second copy. The
# template and the target are on the same device by construction: the Dockerfile
# `mv`s one to the other.
#
# Emptiness cannot decide this. The failed copy left `.next` PARTLY populated, the
# old `ls -A` test then read that as initialized, and every restart afterwards
# started the application against a half-written build -- which exits 0 without ever
# binding its port, so it reads as the app simply refusing to run. A partial state
# has to be distinguishable from a finished one.
MARKER="$TARGET/.droplive-initialized"

if [ ! -f "$MARKER" ]; then
  echo "[droplive-init] initializing $TARGET from $TEMPLATE"
  # Clear anything a previous failed attempt left, or the move lands beside it.
  rm -rf "${TARGET:?}"/* "${TARGET:?}"/.[!.]* 2>/dev/null || true
  if ! mv "$TEMPLATE"/* "$TARGET"/ 2>/dev/null; then
    # A different filesystem: fall back to copying, and fail LOUDLY if it cannot
    # finish rather than leaving a half-written build to start against.
    cp -a "$TEMPLATE/." "$TARGET/" || {
      echo "[droplive-init] could not initialize $TARGET" >&2
      exit 1
    }
  fi
  touch "$MARKER"
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
