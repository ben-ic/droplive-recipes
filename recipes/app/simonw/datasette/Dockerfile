FROM docker.io/datasetteproject/datasette@sha256:0f57db16cf4eb6cca57f1cedaa0a696bca1c65a1d75b8f7ee372c2dd909a32a0

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/simonw/datasette" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

EXPOSE 8001

# The image's own command binds Uvicorn to 127.0.0.1, so nothing outside the
# container can reach it: "Uvicorn running on http://127.0.0.1:8001". Serve on
# all interfaces instead, and open the demo on an empty instance the visitor can
# load data into.
CMD ["datasette", "serve", "--host", "0.0.0.0", "--port", "8001"]
