#!/bin/sh
set -eu

# Laravel writes into storage/ constantly -- compiled Blade views, the session
# and cache stores, and its own log -- so a read-only root stops the first
# request with a 500:
#
#   The stream or file "/var/www/html/storage/logs/laravel.log" could not be
#   opened in append mode: Failed to open stream: Read-only file system
#
# It also needs the directory TREE that the image ships, not an empty directory:
# Blade compiles into storage/framework/views and does not create it. A managed
# path gives writability and arrives empty, which is the wrong half on its own,
# so the image's own storage/ is kept aside at build time and restored here.
#
# Copied only when the mount is empty, so a restart keeps whatever the session
# has written.
if [ -z "$(ls -A /var/www/html/storage 2>/dev/null)" ]; then
  cp -a /opt/droplive-storage-template/. /var/www/html/storage/
fi

exec /startup.sh "$@"
