#!/bin/sh
set -eu

: "${DATABASE_URL:?DropLive supplies the MySQL connection URL}"
: "${APP_URL:?DropLive supplies the public origin}"

# The platform owns one standard companion URL. Ghost's config uses split
# fields, so read the URL with Node (present in the official image) and pass
# only the decoded components to Ghost.
ghost_db_host="$(node -p 'new URL(process.env.DATABASE_URL).hostname')"
ghost_db_port="$(node -p 'new URL(process.env.DATABASE_URL).port || "3306"')"
ghost_db_user="$(node -p 'decodeURIComponent(new URL(process.env.DATABASE_URL).username)')"
ghost_db_password="$(node -p 'decodeURIComponent(new URL(process.env.DATABASE_URL).password)')"
ghost_db_database="$(node -p 'decodeURIComponent(new URL(process.env.DATABASE_URL).pathname.slice(1))')"

export database__client=mysql
export database__connection__host="$ghost_db_host"
export database__connection__port="$ghost_db_port"
export database__connection__user="$ghost_db_user"
export database__connection__password="$ghost_db_password"
export database__connection__database="$ghost_db_database"

# The companion may be created at the same time as the app. Ghost exits if its
# first connection happens before MySQL is listening, so wait for the reviewed
# host and port before handing control to the official entrypoint.
export DB_HOST="$ghost_db_host" DB_PORT="$ghost_db_port"
db_ready=false
for _ in $(seq 1 60); do
  if node -e 'const net = require("node:net"); const socket = net.createConnection({host: process.env.DB_HOST, port: Number(process.env.DB_PORT)}); const fail = () => process.exit(1); socket.once("connect", () => { socket.destroy(); process.exit(0); }); socket.once("error", fail); socket.setTimeout(1000, fail);'; then
    db_ready=true
    break
  fi
  sleep 1
done

if [ "$db_ready" != true ]; then
  echo "Ghost database did not become reachable at ${ghost_db_host}:${ghost_db_port}" >&2
  exit 1
fi

export url="$APP_URL"
export server__host=0.0.0.0
export server__port=2368

exec docker-entrypoint.sh "$@"
