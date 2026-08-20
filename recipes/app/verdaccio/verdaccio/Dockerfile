FROM docker.io/verdaccio/verdaccio@sha256:58353ed1b53ebb3e6fc2925a5384f70a4aa3ddac7a1402d717a39951e7ab43ad

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint

EXPOSE 4873

# Wraps the image's own entrypoint rather than replacing it: `uid_entrypoint` is
# what lets this image run as an arbitrary UID, and the CMD it is given stays the
# image's own.
ENTRYPOINT ["/usr/local/bin/droplive-entrypoint"]
