#!/usr/bin/env bash
set -euo pipefail

data_path=${GROCY_DATAPATH:-/var/www/grocy-data}
config=$data_path/config.php
marker='DropLive deterministic first-owner bootstrap'

mkdir -p "$data_path/plugins" "$data_path/viewcache"

if [[ ! -f "$config" ]]; then
    cp /app/www/config-dist.php "$config"
fi

if ! grep -Fq "$marker" "$config"; then
    cat >>"$config" <<'PHP'

// DropLive deterministic first-owner bootstrap. Grocy consumes these legacy
// constants only while migration 0027 creates the first database user.
if (!defined('GROCY_HTTP_USER')) {
	define('GROCY_HTTP_USER', 'admin');
}
if (!defined('GROCY_HTTP_PASSWORD')) {
	define('GROCY_HTTP_PASSWORD', getenv('GROCY_ADMIN_PASSWORD'));
}
PHP
fi

chown -R abc:abc "$data_path"
