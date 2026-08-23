FROM docker.io/gogs/gogs@sha256:3c7dbdf05a64471296eddf510312589aa8f478c795387993fabcf5d54c68e5cd AS upstream

# Docker creates anonymous filesystems for inherited OCI VOLUME paths. DropLive
# uses the session's private writable rootfs instead. Copy into a clean stage so
# /data remains part of that rootfs and the official entrypoint can initialize it.
FROM scratch
COPY --from=upstream / /

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/gogs/gogs" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    GOGS_CUSTOM=/data/gogs

WORKDIR /app/gogs

RUN mkdir -p /data /backup

EXPOSE 3000

# The Northstar repositories and their open issues, one complete request per
# line, created through Gogs' own API.
COPY --chmod=0444 seed/gogs.requests /usr/local/lib/droplive-gogs-seed.requests
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-gogs

# The upstream pair becomes the command, so the configuration and the seed wrap
# the real startup rather than replacing it.
ENTRYPOINT ["/usr/local/bin/droplive-gogs"]
CMD ["/app/gogs/docker/start.sh", "/usr/bin/s6-svscan", "/app/gogs/docker/s6/"]
