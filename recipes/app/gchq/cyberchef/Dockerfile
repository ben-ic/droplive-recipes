FROM ghcr.io/gchq/cyberchef@sha256:58f68a92fb8e896028f0bb314e6cf5684c9551a84c0b0b2422450ee109b1e883

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# Same image shape as BentoPDF: the official nginx entrypoint creates its request
# cache at startup, and the run plane keeps the root filesystem read-only with
# /tmp as ephemeral writable memory. Point the cache below that boundary instead
# of adding persistent data. CyberChef is browser-local, so nothing here is
# state worth keeping.
USER root
RUN rm -rf /var/cache/nginx /etc/nginx/tmp \
    && ln -s /tmp /var/cache/nginx \
    && ln -s /tmp /etc/nginx/tmp
USER 101

EXPOSE 8080
