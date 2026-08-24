# syntax=docker/dockerfile:1

# Official Dagu 2.7.5 linux/amd64 image pinned to its immutable manifest.
FROM ghcr.io/dagucloud/dagu@sha256:7273b145e94d6339801675480029d710f9227e2d3807bdbc89c1aba3856eab20

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.droplive.source.commit="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}" \
      org.droplive.runtime.contract="dagu-2.7.5"

USER root

# Upstream's general-purpose image grants the workflow user passwordless sudo.
# DropLive does not expose host Docker or devices, so this recipe removes that
# unused escalation path. Normalize the upstream fallback
# UID/GID to a deterministic non-root identity at image-build time.
RUN rm -f /etc/sudoers.d/99-dagu /usr/bin/sudo && \
    usermod -u 1000 dagu && \
    groupmod -g 1000 dagu && \
    chown -R 1000:1000 /home/dagu /var/lib/dagu

COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint
COPY --chmod=0555 healthcheck.sh /usr/local/bin/droplive-healthcheck
COPY --chown=1000:1000 --chmod=0444 seed/ /opt/droplive/dags/
RUN chmod 0755 /opt/droplive

LABEL org.opencontainers.image.version="2.7.5" \
      org.opencontainers.image.revision="e8ba3ef2387cc93cbcf609e15fd0b3f249f0e51e" \
      org.opencontainers.image.source="https://github.com/dagucloud/dagu" \
      org.opencontainers.image.licenses="GPL-3.0-only" \
      io.droplive.recipe-modification="Removed passwordless sudo, deterministic non-root runtime, generated initial owner, bounded concurrency, managed persistence, and four safe starter workflows"
LABEL io.droplive.data-backup=files

ENV DAGU_HOME=/var/lib/dagu \
    DAGU_HOST=0.0.0.0 \
    DAGU_PORT=8080 \
    DAGU_TZ=Etc/UTC \
    DAGU_AUTH_MODE=builtin \
    DAGU_AUTH_BUILTIN_INITIAL_ADMIN_USERNAME=admin \
    DAGU_TERMINAL_ENABLED=false \
    DAGU_GITSYNC_ENABLED=false \
    DAGU_WORKER_MAX_ACTIVE_RUNS=4 \
    DAGU_LOG_FORMAT=text \
    DOCKER_GID=-1

VOLUME ["/var/lib/dagu"]
EXPOSE 8080

HEALTHCHECK --start-period=20s --interval=30s --timeout=5s --retries=3 \
  CMD ["/usr/local/bin/droplive-healthcheck", "http://127.0.0.1:8080/api/v1/health"]
LABEL io.droplive.readiness.contains.health='"status":"healthy"'

ENTRYPOINT ["/usr/local/bin/droplive-entrypoint"]
