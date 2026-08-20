FROM ghcr.io/nodebb/nodebb@sha256:b20c572cd4fc0b86faa0553c1f50fe601bdf30e4bd5c3fed02fcce005f540d41

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/NodeBB/NodeBB" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

EXPOSE 4567
