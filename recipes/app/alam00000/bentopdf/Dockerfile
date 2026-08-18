# BentoPDF v2.8.7 official self-hosted linux/amd64 image manifest.
FROM ghcr.io/alam00000/bentopdf-simple@sha256:a81ad6219398f4d6714ca52dd04d2767a7a2318b72edbf03a259c71c2f81914d

# The run plane keeps the image root filesystem read-only and provides /tmp as
# ephemeral writable memory. Nginx creates its request cache at startup, so put
# that cache below the existing /tmp boundary instead of adding persistent data.
USER root
RUN rm -rf /var/cache/nginx /etc/nginx/tmp \
    && ln -s /tmp /var/cache/nginx \
    && ln -s /tmp /etc/nginx/tmp
USER 101

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

EXPOSE 8080
