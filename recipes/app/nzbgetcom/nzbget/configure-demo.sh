#!/bin/sh
set -eu

# The published image ships one fixed HTTP credential. A DropLive session is
# already private, so remove it instead of hiding a shared password from users.
mkdir -p /downloads/completed /downloads/intermediate
chown 911:911 /downloads /downloads/completed /downloads/intermediate

sed -i \
  -e 's/^ControlUsername=.*/ControlUsername=/' \
  -e 's/^ControlPassword=.*/ControlPassword=/' \
  /config/nzbget.conf
