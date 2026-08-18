# syntax=docker/dockerfile:1

# Official Uptime Kuma 2.5.0 slim-rootless linux/amd64 image, pinned to its
# immutable platform manifest. The slim shape deliberately omits embedded
# Chromium and MariaDB; the default recipe uses HTTP monitoring and SQLite.
FROM louislam/uptime-kuma@sha256:caf5a78910bce721f68a96d63d147990c4e1652e9f3c5b225d2edda5d97ea01f

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --chown=1000:1000 --chmod=0555 healthcheck.cjs /usr/local/lib/droplive-uptime-kuma-healthcheck.cjs

LABEL org.opencontainers.image.version="2.5.0" \
      org.opencontainers.image.revision="d9a60dfc73140d15111752e4e8910ed4b54bd9a3" \
      org.opencontainers.image.source="https://github.com/louislam/uptime-kuma" \
      org.opencontainers.image.licenses="MIT" \
      io.droplive.security.docker-socket="disabled"
LABEL io.droplive.data-backup=files
LABEL io.droplive.readiness.contains.health='Uptime Kuma'

ENV DATA_DIR=/app/data \
    UPTIME_KUMA_HOST=0.0.0.0 \
    UPTIME_KUMA_PORT=3001

USER 1000:1000
WORKDIR /app
VOLUME ["/app/data"]
EXPOSE 3001

HEALTHCHECK --start-period=30s --interval=30s --timeout=5s --retries=5 \
  CMD ["node", "/usr/local/lib/droplive-uptime-kuma-healthcheck.cjs", "http://127.0.0.1:3001/dashboard"]
