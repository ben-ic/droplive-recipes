#!/bin/sh
set -eu

: "${APP_URL:?DropLive supplies the public application URL}"

public_host=${APP_URL#*://}
public_host=${public_host%%/*}
public_host=${public_host%%:*}

case "$public_host" in
  ''|*[!A-Za-z0-9.-]*)
    echo "SABnzbd public host is invalid" >&2
    exit 1
    ;;
esac

# SABnzbd rejects an unknown Host header with 403. Keep its generated local
# hostname and add only this private demo's assigned public hostname. The
# custom init runs before SABnzbd creates its first configuration file.
container_host=$(hostname)
case "$container_host" in
  ''|*[!A-Za-z0-9.-]*)
    echo "SABnzbd container host is invalid" >&2
    exit 1
    ;;
esac

if [ -f /config/sabnzbd.ini ]; then
  sed -i \
    "s/^host_whitelist = .*/host_whitelist = ${container_host},${public_host},/" \
    /config/sabnzbd.ini
else
  printf '[misc]\nhost_whitelist = %s,%s,\n' \
    "$container_host" "$public_host" > /config/sabnzbd.ini
fi

chown 911:911 /config/sabnzbd.ini
