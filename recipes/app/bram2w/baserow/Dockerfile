FROM docker.io/baserow/baserow@sha256:41adb3493379403946a493f30873f743bb65b19b5f387d630ec75f41e25d5b5b

# DropLive mounts /baserow/data from the declared data volume. Baserow cannot
# detect that mount inside the build probe, so disable only its duplicate check.
ENV DISABLE_VOLUME_CHECK=yes

# Baserow binds both internal servers to IPv4, but this release overwrites its
# proxy targets with `localhost`. On hosts where that name resolves to `::1`,
# Caddy cannot reach the IPv4-only servers. Keep explicit recipe targets and use
# the matching IPv4 addresses by default.
RUN sed -i \
      -e 's|^export PRIVATE_BACKEND_URL=.*|export PRIVATE_BACKEND_URL=${PRIVATE_BACKEND_URL:-http://127.0.0.1:8000}|' \
      -e 's|^export PRIVATE_WEB_FRONTEND_URL=.*|export PRIVATE_WEB_FRONTEND_URL=${PRIVATE_WEB_FRONTEND_URL:-http://127.0.0.1:3000}|' \
      /baserow/supervisor/default_baserow_env.sh

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/bram2w/baserow" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --chmod=755 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/droplive-entrypoint"]
CMD ["start"]
