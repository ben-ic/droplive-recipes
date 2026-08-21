FROM ghcr.io/advplyr/audiobookshelf@sha256:e12511a64b9a7af3657889995f016f8757640169d174a83ce631cbf505a5dbca

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --chmod=755 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint
COPY bootstrap.mjs /usr/local/lib/droplive-audiobookshelf-bootstrap.mjs

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/droplive-entrypoint"]
CMD ["node", "index.js"]
