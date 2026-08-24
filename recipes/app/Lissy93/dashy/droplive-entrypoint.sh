#!/bin/sh
set -eu

# Dashy stores its dashboard configuration in the managed user-data directory.
# A fresh image populates that volume with its own default config. Replace only
# that exact pinned default, or a missing file; UI changes remain user-owned.
default_config_sha256=52e035cf3b41e9750b650d5a61cac028a9db476cd5d6e698f594c22ff1995db6
current_config_sha256=""
if [ -e /app/user-data/conf.yml ]; then
  current_config_sha256="$(sha256sum /app/user-data/conf.yml | awk '{print $1}')"
fi

if [ ! -e /app/user-data/conf.yml ] || [ "$current_config_sha256" = "$default_config_sha256" ]; then
  cp /opt/droplive/dashy/conf.yml /app/user-data/conf.yml
fi

exec /sbin/tini -- "$@"
