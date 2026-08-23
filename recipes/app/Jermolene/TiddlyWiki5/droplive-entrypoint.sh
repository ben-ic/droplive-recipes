#!/bin/sh
# Put the Northstar tiddlers in the wiki before the server starts.
#
# The tiddlers are kept OUT of /var/lib/tiddlywiki and copied in here.
# That path is a declared volume, and a managed block volume can mount empty
# instead of applying Docker's named-volume copy-up, which would serve a wiki
# with nothing in it. Copying at startup works either way.
#
# The wiki has to exist before it can hold anything, so this runs the image's own
# `--init server` when it is absent; the command that follows then finds mywiki
# and skips its own init.
set -eu

SEED=/usr/local/lib/droplive-tiddlywiki-tiddlers
WIKI=/var/lib/tiddlywiki/mywiki

if [ -d "$SEED" ] && [ ! -d "$WIKI" ]; then
  tiddlywiki_script=$(readlink -f "$(which tiddlywiki)")
  node "$tiddlywiki_script" mywiki --init server
  mkdir -p "$WIKI/tiddlers"
  cp -a "$SEED"/. "$WIKI/tiddlers"/
  echo "[droplive] wrote the Northstar tiddlers" >&2
fi

exec "$@"
