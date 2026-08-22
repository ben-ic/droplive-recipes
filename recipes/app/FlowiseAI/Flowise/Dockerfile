FROM docker.io/flowiseai/flowise@sha256:cf880b17b1290fbaebebc76c33954bde67b3775aff95feec72a1d060cc81e43d

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/FlowiseAI/Flowise" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# Flowise 3.1.2 resolves connect-sqlite3 0.9.17, whose database API is not
# compatible with this Flowise release. Use Flowise's supported PostgreSQL path.
ENV DATABASE_TYPE=postgres

EXPOSE 3000
