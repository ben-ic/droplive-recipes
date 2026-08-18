#!/bin/sh
set -eu

# Use the existing exact platform-owned bootstrap name, then map it to SiYuan's
# upstream variable. Generic AUTH_CODE matching would capture external providers.
# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=APP_ADMIN_PASSWORD capability=owner-login
: "${APP_ADMIN_PASSWORD:?DropLive must generate the owner lock-screen credential}"
export SIYUAN_ACCESS_AUTH_CODE="$APP_ADMIN_PASSWORD"

# Upstream's entrypoint is deliberately NOT used. It prepares the container at
# runtime: `addgroup`/`adduser` for PUID/PGID, then `chown -R` over /opt/siyuan,
# /home/siyuan and the workspace, then `su-exec` down to the new user. Every one
# of those writes to the root filesystem, which this run plane mounts read-only,
# so it fails on /etc/group and the container crash-loops before the kernel ever
# binds 6806.
#
# The kernel is therefore executed directly. HOME points at ephemeral /tmp
# because the root filesystem is read-only and nothing under it is meant to
# survive the session; the workspace is the one persistent path.
mkdir -p "$HOME" /tmp/siyuan-config
exec /opt/siyuan/kernel --workspace="${SIYUAN_WORKSPACE_PATH}" "$@"
