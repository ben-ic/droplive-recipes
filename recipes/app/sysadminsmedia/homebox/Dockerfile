# Homebox v0.26.2 official linux/amd64 hardened image, pinned immutably.
FROM ghcr.io/sysadminsmedia/homebox@sha256:471074b72cd0dd825da47a0e8975675ee5e4b59d0c29b8702ea7d3e6ba204324

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

LABEL io.droplive.recipe-source="https://github.com/sysadminsmedia/homebox/tree/v0.26.2"
LABEL io.droplive.data-backup=sqlite

# Keep the starter private-by-default from upstream telemetry and remove the
# mutable release-check network request. User registration remains enabled so
# the owner can complete Homebox's normal first-user flow.
ENV HBOX_OPTIONS_ALLOW_ANALYTICS=false \
    HBOX_OPTIONS_GITHUB_RELEASE_CHECK=false

# The upstream image already carries this metadata. Repeat the managed volume
# and single known port because DropLive's current pre-build exact-Dockerfile
# path does not resolve inherited base-image configuration.
VOLUME ["/data"]
EXPOSE 7745

# Repeat the official image's meaningful application-status probe so the
# source-Dockerfile planner does not fall back to a shallow GET / readiness
# check when it cannot inspect inherited image metadata.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["/app/healthcheck", "http://127.0.0.1:7745/api/v1/status"]
