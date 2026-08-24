FROM docker.io/getmeili/meilisearch@sha256:8d6643d86d71fad6ad3cba92cde7ccfce9e4d6c384bda67598eb553571c32431

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/meilisearch/meilisearch" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-meilisearch-entrypoint

VOLUME ["/meili_data"]
EXPOSE 7700
ENTRYPOINT ["/usr/local/bin/droplive-meilisearch-entrypoint"]
