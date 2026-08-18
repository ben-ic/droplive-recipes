#!/bin/sh
set -e

# Upstream otherwise falls back to a documented weak literal signing secret.
# Fail closed so Automatic must supply the generated ownership contract.
# droplive: generate=hex96 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=app name=EBK_SECURITY_SECRET_KEY
: "${EBK_SECURITY_SECRET_KEY:?DropLive must generate EBK_SECURITY_SECRET_KEY}"
: "${EBK_SERVER_ROOT_URL:?DropLive must derive EBK_SERVER_ROOT_URL from the public origin}"

# ezBookkeeping validates that local_filesystem_path already exists before its
# storage layer creates avatar/transaction subdirectories. DropLive presents an
# empty, writable managed volume, so initialize the documented root as the
# inherited non-root UID/GID 1000 on every start.
mkdir -p /data/storage

exec /docker-entrypoint.sh "$@"
