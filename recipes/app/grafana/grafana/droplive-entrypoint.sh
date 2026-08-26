#!/bin/sh
set -eu

dashboard_dir=/var/lib/grafana/dashboards
seed_marker=$dashboard_dir/.droplive-northstar-v2
mkdir -p "$dashboard_dir"

# The published image can contain a SQLite admin database created during its
# build probe. A public demo is disposable, so discard that stale identity and
# let Grafana create the admin user from this session's password. Tenant
# launches do not receive DROPLIVE_DEMO and keep their persistent database.
if [ "${DROPLIVE_DEMO:-}" = "1" ]; then
  rm -f "${GF_PATHS_DATA:-/var/lib/grafana}/grafana.db"
fi

if ! test -e "$seed_marker"; then
  cp /opt/droplive/northstar-relay.json "$dashboard_dir/northstar-relay.json"
  touch "$seed_marker"
fi
exec /run.sh "$@"
