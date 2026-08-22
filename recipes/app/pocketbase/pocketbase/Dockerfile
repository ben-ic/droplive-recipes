FROM ghcr.io/muchobien/pocketbase@sha256:3854997f39cb005bc33c73cdd2c52a83cc4fbafe116570e625761ae1dcf152ec

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/pocketbase/pocketbase" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --chmod=755 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint

EXPOSE 8090

ENTRYPOINT ["/usr/local/bin/droplive-entrypoint"]
