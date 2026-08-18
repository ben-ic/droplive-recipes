# LubeLogger v1.7.0 official linux/amd64 image, pinned immutably.
FROM ghcr.io/hargata/lubelogger@sha256:3aeb1bd541e24746e859409b983a1ba73c7030b590bb3bca9aa4add48fb4b52c

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

LABEL io.droplive.recipe-source="https://github.com/hargata/lubelog/tree/v1.7.0"
LABEL io.droplive.data-backup=files

COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-lubelogger-entrypoint
COPY --chmod=0555 healthcheck.sh /usr/local/bin/droplive-lubelogger-healthcheck

# Keep the official image's existing unprivileged account. HOME places ASP.NET
# data-protection keys inside the same managed directory as LiteDB, uploads, and
# configuration so sessions remain valid and backup/restore is complete.
RUN install -d -o 1654 -g 1654 -m 0700 /App/data
ENV HOME=/App/data \
    LUBELOGGER_INVARIANT_API=true

# Repeat the pinned base image's exact case-sensitive WORKDIR so DropLive can
# carry and independently validate the `/App/data` mount root from source.
WORKDIR /App
VOLUME ["/App/data"]
EXPOSE 8080

# /health returns HTTP 500 if the active LiteDB connection check fails.
HEALTHCHECK --start-period=15s --interval=30s --timeout=5s --retries=4 \
  CMD ["/usr/local/bin/droplive-lubelogger-healthcheck", "http://127.0.0.1:8080/health"]

USER 1654:1654
ENTRYPOINT ["/usr/local/bin/droplive-lubelogger-entrypoint"]
CMD ["./CarCareTracker"]
