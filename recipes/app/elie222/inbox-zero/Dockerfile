# The pinned upstream image, unchanged.
#
# This recipe used to move `.next` aside at build time and restore it from an
# entrypoint, because `start.sh` rewrites the built bundles with per-session
# NEXT_PUBLIC_* values and a read-only root refused. The demo now gets a writable
# copy-on-write root populated from the image, so the build output is writable
# where it already is, and the image's own entrypoint runs again.
FROM ghcr.io/elie222/inbox-zero@sha256:b543689db188d252b7032327129f9f019c0d3257a4febff7a98005cd9318ec14

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256

EXPOSE 3000
