FROM docker.io/langflowai/langflow@sha256:3fe9a758b8a4fa9bbeec726d71d2f69391643bfc20c175288c1b4e166b7348fb

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/langflow-ai/langflow" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# Read once at boot to create the superuser. Only the password is secret; see
# droplive.yaml.
ENV LANGFLOW_SUPERUSER=admin

EXPOSE 7860
