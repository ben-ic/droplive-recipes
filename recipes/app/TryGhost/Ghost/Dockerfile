FROM docker.io/ghost@sha256:789dee0d3e8c462ee75813e4f0fda31809a70c98097ded9059a4c72553db909c

COPY --chmod=755 entrypoint.sh /usr/local/bin/droplive-entrypoint

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/TryGhost/Ghost" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

EXPOSE 2368

ENTRYPOINT ["/usr/local/bin/droplive-entrypoint"]
