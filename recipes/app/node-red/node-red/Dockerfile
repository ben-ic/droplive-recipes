# syntax=docker/dockerfile:1

# Official Node-RED 4.1.10 linux/amd64 manifest, pinned immutably.
FROM nodered/node-red@sha256:7c305b9a23b559bf44f2c9dc8fd7f2e6d5038426113f21999e63563a58f38755

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.droplive.source.commit="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}" \
      org.droplive.runtime.contract="node-red-4.1.10"

USER root

# The official image includes an empty placeholder flow under /data. Remove it
# before declaring the managed volume so the wrapper can seed the same starter
# flow in both a test build and a new managed volume.
RUN rm -f /data/flows.json

LABEL org.opencontainers.image.version="4.1.10" \
      org.opencontainers.image.revision="c6d8328a4b7e7087d26b2bf069d3939d8d8ee528" \
      org.opencontainers.image.source="https://github.com/node-red/node-red" \
      org.opencontainers.image.licenses="Apache-2.0" \
      io.droplive.recipe-modification="Generated editor authentication, stable credential encryption, starter health flow, and managed persistence"
LABEL io.droplive.data-backup=files

COPY --chmod=0555 droplive-entrypoint.sh /usr/src/node-red/droplive-entrypoint.sh
COPY --chown=node-red:root --chmod=0444 settings.js /usr/src/node-red/droplive-settings.js
COPY --chown=node-red:root --chmod=0444 flows.json /usr/src/node-red/droplive-flows.json

ENV NODE_OPTIONS="--max-old-space-size=384"

VOLUME ["/data"]
EXPOSE 1880

HEALTHCHECK --start-period=30s --interval=30s --timeout=5s --retries=3 \
  CMD ["curl", "--fail", "--silent", "--show-error", "http://127.0.0.1:1880/healthz"]

ENTRYPOINT ["/usr/src/node-red/droplive-entrypoint.sh"]
