FROM ghcr.io/paperless-ngx/paperless-ngx@sha256:65a4cabf0169ea7fbd90ab7bb28ba3f8b5909613635acda1a03ad606f34b456b

# Paperless creates this administrator when DropLive supplies the per-demo
# password declared in the recipe.
ENV PAPERLESS_ADMIN_USER=admin

# PAPERLESS_URL makes Django trust the assigned public origin for login POSTs.
# Keep the pinned image's /init process as PID 1 after the wrapper binds it.
COPY droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint
RUN chmod 0755 /usr/local/bin/droplive-entrypoint
ENTRYPOINT ["/usr/local/bin/droplive-entrypoint"]

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/paperless-ngx/paperless-ngx" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

EXPOSE 8000
