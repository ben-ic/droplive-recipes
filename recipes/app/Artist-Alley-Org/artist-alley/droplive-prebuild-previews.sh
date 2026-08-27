#!/bin/sh
set -eu

pg_bin=$(dirname "$(find /usr/lib/postgresql -path '*/bin/initdb' -print -quit)")
if [ ! -x "$pg_bin/initdb" ]; then
  echo "PostgreSQL build tools are unavailable" >&2
  exit 1
fi
PATH="$pg_bin:$PATH"
export PATH

pg_data=/tmp/droplive-preview-postgres
storage_root=/tmp/droplive-preview-cache
app_log=/tmp/droplive-preview-app.log
app_pid=

cleanup() {
  trap - INT TERM EXIT
  if [ -n "$app_pid" ]; then
    kill "$app_pid" 2>/dev/null || true
    wait "$app_pid" 2>/dev/null || true
  fi
  pg_ctl -D "$pg_data" -m fast -w stop >/dev/null 2>&1 || true
}
trap cleanup INT TERM EXIT

rm -rf "$pg_data" "$storage_root"
mkdir -p "$pg_data" "$storage_root" /tmp/droplive-preview-bootstrap
initdb -D "$pg_data" --username=artist_alley --auth=trust --no-locale >/dev/null
pg_ctl -D "$pg_data" \
  -o "-c listen_addresses=127.0.0.1 -c unix_socket_directories=/tmp -p 55432" \
  -w start >/dev/null
createdb -h 127.0.0.1 -p 55432 -U artist_alley artist_alley

export AA_HTTP_ADDR=127.0.0.1:18081
export AA_DB_HOST=127.0.0.1
export AA_DB_PORT=55432
export AA_DB_USER=artist_alley
export AA_DB_PASSWORD=droplive-preview-build-only
export AA_DB_NAME=artist_alley
export AA_DB_SSLMODE=disable
export AA_SCRAMBLE_KEY=droplive-preview-build-only
export AA_MASTER_KEY=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
export AA_STORAGE_BACKEND=fs
export AA_STORAGE_FS_ROOT="$storage_root"
export AA_BOOTSTRAP_ADMIN_PATH=/tmp/droplive-preview-bootstrap
export AA_LOG_LEVEL=info
export AA_LOG_FORMAT=json

AA_BOOTSTRAP_DEFAULT_ADMIN=1 /app/aa seed \
  --site /opt/artist-alley-prepared/site \
  --catalogue /opt/artist-alley-prepared/catalogue \
  --previews=true

/app/aa >"$app_log" 2>&1 &
app_pid=$!

attempt=0
until curl -fsS http://127.0.0.1:18081/healthz >/dev/null; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 45 ]; then
    tail -n 80 "$app_log" >&2
    echo "Artist Alley preview worker did not start" >&2
    exit 1
  fi
  sleep 1
done

attempt=0
while :; do
  outstanding=$(psql -h 127.0.0.1 -p 55432 -U artist_alley -d artist_alley -tAc \
    "SELECT count(*) FROM jobs WHERE status IN ('pending','running') AND type LIKE 'preview.%';")
  if [ "$outstanding" = 0 ]; then
    break
  fi
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 48 ]; then
    psql -h 127.0.0.1 -p 55432 -U artist_alley -d artist_alley -Atc \
      "SELECT type || ' ' || status || ' x' || count(*) FROM jobs WHERE status IN ('pending','running') AND type LIKE 'preview.%' GROUP BY type,status ORDER BY type,status;" >&2
    tail -n 80 "$app_log" >&2
    echo "Artist Alley preview queue did not drain within 240 seconds" >&2
    exit 1
  fi
  sleep 5
done

rendered=$(find "$storage_root" -type f -name col | wc -l | tr -d ' ')
if [ "$rendered" -lt 30 ]; then
  tail -n 80 "$app_log" >&2
  echo "Artist Alley prepared only $rendered card previews" >&2
  exit 1
fi

# Runtime seeding writes the originals from the small prepared site. Keep only
# derivatives here, so the final image does not store each source file twice.
find "$storage_root" -type f -name original -delete
find "$storage_root" -type d -empty -delete
echo "prepared $rendered real card previews"

cleanup
