FROM ghcr.io/silverbulletmd/silverbullet@sha256:27b5724cc36798e7de82180ec9898ea9c157c4f15127f279834bca2897b91f37

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# The Northstar company as twenty-five linked markdown pages. Kept out of the
# volume on purpose -- the entrypoint copies them in, see there for why.
COPY seed/space/ /usr/local/lib/droplive-silverbullet-space/
COPY --chmod=0755 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint

ENV SB_HOSTNAME=0.0.0.0 \
    SB_FOLDER=/app/data \
    SB_PORT=3000 \
    SB_RUNTIME_API=0 \
    SB_SHELL_BACKEND=off

VOLUME ["/app/data"]
LABEL io.droplive.data-backup=files
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s \
  CMD curl --fail --silent http://127.0.0.1:3000/.instance || exit 1

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/droplive-entrypoint"]
