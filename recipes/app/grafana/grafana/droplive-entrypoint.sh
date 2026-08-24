#!/bin/sh
set -eu

dashboard_dir=/var/lib/grafana/dashboards
seed_marker=$dashboard_dir/.droplive-northstar-v1
mkdir -p "$dashboard_dir"
if ! test -e "$seed_marker"; then
  cp /opt/droplive/northstar-relay.json "$dashboard_dir/northstar-relay.json"
  touch "$seed_marker"
fi
exec /run.sh "$@"
