#!/bin/bash
# Put the Northstar wiki in place before nginx serves it.
#
# This is a LinuxServer custom init script, which is the extension point this
# image documents: /custom-cont-init.d runs during startup, before the service,
# with the config volume already mounted. That matters here -- /config is a
# declared volume, and a managed block volume can mount empty instead of applying
# Docker's named-volume copy-up, so pages baked into the image path would not be
# there. Copying at startup works either way.
set -euo pipefail

seed=/usr/local/lib/droplive-dokuwiki-pages
pages=/config/dokuwiki/data/pages
local_conf=/config/dokuwiki/conf/local.php

[[ -d "$seed" ]] || exit 0

# IDEMPOTENT ON DOKUWIKI'S OWN START PAGE. If it is there this wiki has been
# written, and a restart leaves every page alone -- including any a visitor
# edited during the demo.
if [[ ! -e "$pages/start.txt" ]]; then
  mkdir -p "$pages"
  cp -a "$seed"/. "$pages"/
  # The image ships a playground and a copy of DokuWiki's own manual. Useful in a
  # fresh install, noise in a demo of one company's wiki.
  rm -rf "$pages/playground" "$pages/wiki"
  echo "[droplive] wrote the Northstar wiki"
fi

if [[ ! -e "$local_conf" ]]; then
  cat >"$local_conf" <<'PHP'
<?php
$conf['title'] = 'Northstar Relay';
$conf['tagline'] = 'A small software company that automates large operational data exports.';
$conf['useacl'] = 0;
$conf['breadcrumbs'] = 10;
$conf['youarehere'] = 1;
PHP
fi

# DokuWiki decides what a page contains by reading it, but it decides what exists
# from an index it builds as pages are saved. These were not saved, they were
# copied, so search and the page list stay empty until the index is built once.
if [[ -x /usr/bin/php83 || -x /usr/bin/php ]]; then
  php="$(command -v php83 || command -v php)"
  s6-setuidgid abc "$php" /app/dokuwiki/bin/indexer.php -c 2>/dev/null || true
fi

chown -R abc:abc "$pages" "$local_conf" 2>/dev/null || true
