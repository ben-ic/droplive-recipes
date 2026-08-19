FROM docker.io/nicolargo/glances@sha256:3690a895a732e8d14d230c2b698fc044b1d5b1b9d56a46a5bc9d69f6f6c9fd6f

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

EXPOSE 61208

# Without a command the image starts the CURSES ui, which has no terminal here:
# "Cannot init the curses library (setupterm: could not find terminal)". -w is the
# web server the recipe declares a port and health path for.
CMD ["glances", "-w", "--port", "61208"]

