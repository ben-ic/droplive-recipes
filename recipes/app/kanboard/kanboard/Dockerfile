# Kanboard v1.2.44, official linux/amd64 image manifest.
FROM docker.io/kanboard/kanboard@sha256:064004e1582ee54dc0821e74cc33653b9c547b3faafafa2616e84ac27826ba2e AS upstream

# The image declares /etc/nginx/ssl, /var/www/app/data and /var/www/app/plugins
# as OCI volumes. DropLive gives a demo one private writable rootfs and does not
# apply Docker's named-volume copy-up, so those paths arrive as empty mounts the
# official entrypoint cannot initialize. nginx then crash-loops on a certificate
# nobody generated, forever, and the session never becomes ready:
#
#   nginx: [emerg] cannot load certificate "/etc/nginx/ssl/kanboard.crt"
#
# The directories are made BEFORE the declarations are dropped. A VOLUME path
# exists only as a mountpoint the runtime creates, so a plain copy of the
# filesystem does not contain it, and openssl is then asked to write a
# certificate into a directory that is not there.
FROM upstream AS prepared
RUN mkdir -p /etc/nginx/ssl /var/www/app/data /var/www/app/plugins

# Copying into a clean stage drops the volume declarations, so all three paths
# are ordinary directories in the session's own rootfs. Everything below
# re-states what that stage discards.
FROM scratch
COPY --from=prepared / /

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/kanboard/kanboard" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WORKDIR /

# The Northstar boards, one complete JSON-RPC request body per line. Read by the
# entrypoint and posted to Kanboard's own API, so nothing here writes to SQLite.
COPY --chmod=0444 seed/kanboard.jsonl /usr/local/lib/droplive-kanboard-seed.jsonl
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-kanboard

# What arrives while the visitor is watching. The timeline itself is not here:
# it comes from the read-only world the platform mounts for the session, so this
# is only the adapter that turns its events into comments.
COPY --chmod=0444 seed/arrivals.php /usr/local/lib/droplive-kanboard-arrivals.php

EXPOSE 80

# The upstream entrypoint becomes the command, so the seeder wraps the real
# startup rather than replacing it.
ENTRYPOINT ["/usr/local/bin/droplive-kanboard"]
CMD ["/usr/local/bin/entrypoint.sh"]
