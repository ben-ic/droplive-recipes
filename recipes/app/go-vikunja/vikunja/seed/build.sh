#!/bin/sh
# Play the Northstar seed into a fresh Vikunja database, inside a build stage.
#
# The finished database is what the image carries. Nothing here ends up in the
# running image: no Python, no SQLite tool, no seed file.
set -eu

export VIKUNJA_DATABASE_TYPE=sqlite
export VIKUNJA_DATABASE_PATH=/build/vikunja.db
export VIKUNJA_FILES_BASEPATH=/build/files
export VIKUNJA_SERVICE_ENABLEREGISTRATION=false
export VIKUNJA_MAILER_ENABLED=false
export VIKUNJA_SERVICE_PUBLICURL=http://127.0.0.1:3456/
# A build-only value. The running image gets its own from DropLive, and this
# database carries no session state that outlives the build.
export VIKUNJA_SERVICE_SECRET=0000000000000000000000000000000000000000000000000000000000000000
# SQLite has one writer, and a seed is the one workload that writes as fast as
# it can. One connection turns a contended write into a wait instead of a 500.
export VIKUNJA_DATABASE_MAXOPENCONNECTIONS=1

mkdir -p /build/files

/app/vikunja/vikunja web >/tmp/vikunja-build.log 2>&1 &
server_pid=$!

python3 /seed/run.py

# The dates are corrected only after the server has stopped. Vikunja holds its
# SQLite open, and rewriting rows underneath a running writer is how a demo
# ships a half-written database.
kill "$server_pid"
wait "$server_pid" 2>/dev/null || true
python3 /seed/run.py --dates

rm -f /build/droplive-dates.json
test -s /build/vikunja.db
