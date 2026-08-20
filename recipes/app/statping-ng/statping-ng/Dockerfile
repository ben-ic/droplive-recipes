FROM docker.io/adamboutcher/statping-ng@sha256:e32bd2e50ca023f37b0650e1942d51cb9269a2caab11042bc0cc53fac0474a2b

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/statping-ng/statping-ng" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

EXPOSE 8080
