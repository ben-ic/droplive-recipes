#!/bin/sh
set -eu

: "${DATABASE_URL:?DropLive supplies the MySQL connection URL}"

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

exec docker-entrypoint.sh "$@"
