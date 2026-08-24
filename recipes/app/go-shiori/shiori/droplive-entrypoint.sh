#!/bin/busybox sh
set -eu

# Shiori writes its bookmark database in this managed directory. A database
# already present is user data, so seed only the initial empty volume.
/bin/busybox mkdir -p /data
if [ ! -e /data/shiori.db ]; then
  /usr/bin/shiori --storage-directory /data add --offline --no-archival \
    --title "Product direction" \
    --tags "northstar,product" \
    "https://example.com/product"
  /usr/bin/shiori --storage-directory /data add --offline --no-archival \
    --title "Release readiness" \
    --tags "northstar,releases" \
    "https://example.com/releases"
  /usr/bin/shiori --storage-directory /data add --offline --no-archival \
    --title "Customer notes" \
    --tags "northstar,customers" \
    "https://example.com/customers"
  /usr/bin/shiori --storage-directory /data add --offline --no-archival \
    --title "Support queue" \
    --tags "northstar,support" \
    "https://example.com/support"
fi

exec /usr/bin/shiori --storage-directory /data "$@"
