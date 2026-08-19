#!/bin/sh
set -eu

# The image keeps its shipped configuration and GeoLite2 databases in /staging
# and restores them at startup, so it expects both managed paths to arrive
# empty. That is exactly what a demo gives it, with one gap.
#
# `docker_start.sh` creates /etc/crowdsec before it rsyncs into it, but it links
# the data files with no mkdir first:
#
#   for target in "/staging/var/lib/crowdsec/data"/*; do
#       ln -s "$target" "/var/lib/crowdsec/data/$fname"
#
# Its own comment says "when the data dir is mounted (common case)" -- it counts
# on the mount already containing the empty `data/` the image ships, which is
# true only where a volume is seeded from the image. A DropLive volume starts
# empty, so the directory is simply absent and every link fails:
#
#   ln: /var/lib/crowdsec/data/GeoLite2-ASN.mmdb: No such file or directory
#
# The container exits before it binds a port, so the session waits out its
# fifteen minutes on a µVM that never served anything.
#
# Creating the directory is the whole fix. Leaving it to the image is not an
# option -- dropping the managed paths instead only trades this for
# "Read-only file system" on the same line.
mkdir -p /var/lib/crowdsec/data

exec /bin/bash /docker_start.sh "$@"
