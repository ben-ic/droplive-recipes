#!/bin/sh
set -eu

# Declare that DropLive must generate this owner credential. The annotation
# grammar accepts the `hex96` generator.
# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=SB_ADMIN_PASSWORD capability=owner-login username=admin
: "${SB_ADMIN_PASSWORD:?DropLive must generate SB_ADMIN_PASSWORD with openssl rand -hex 32}"

data_root=${SB_FOLDER:-/app/data}
users_file="$data_root/users.json"
spaces_file="$data_root/spaces.json"

# SilverBullet 2.10's non-interactive setup command is the same implementation
# as its browser wizard. Guard it explicitly: a complete deployment is safe to
# restart, a fresh deployment is provisioned once, and a partial deployment
# stops for recovery instead of silently replacing account metadata.
#
# The adjacent 2.9 release stores a classic single space directly in this
# folder. SilverBullet 2.10 explicitly supports serving a non-empty legacy
# folder unchanged. Keep that supported mode (and its same generated owner
# credential) instead of provisioning an empty new multi-space beside the old
# pages and making them appear lost.
if [ -f "$users_file" ] && [ -f "$spaces_file" ]; then
  :
elif [ ! -e "$users_file" ] && [ ! -e "$spaces_file" ]; then
  if [ -f "$data_root/index.md" ]; then
    export SB_USER="admin:${SB_ADMIN_PASSWORD}"
  else
    /silverbullet setup \
      --admin "admin:${SB_ADMIN_PASSWORD}" \
      --space Personal \
      --at / \
      "$data_root"
  fi
else
  echo "SilverBullet setup is incomplete: users.json and spaces.json must either both exist or both be absent" >&2
  exit 65
fi

exec /silverbullet "$data_root"
