FROM docker.io/gotify/server@sha256:dfbee7fc4701b300936a24b01d24620b4d62e405204c71fd749a63abfb9b4ec4

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-gotify-entrypoint

ENV GOTIFY_DEFAULTUSER_NAME=admin \
    GOTIFY_REGISTRATION=false

VOLUME ["/app/data"]
EXPOSE 80
ENTRYPOINT ["/usr/local/bin/droplive-gotify-entrypoint"]
