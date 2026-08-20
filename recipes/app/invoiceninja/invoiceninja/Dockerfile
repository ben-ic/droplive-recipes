FROM docker.io/invoiceninja/invoiceninja@sha256:4b3f9682a32af4d82b26743f47b9aaf144246cf9049d22163e4098ce87e50611

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/invoiceninja/invoiceninja" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

EXPOSE 80
