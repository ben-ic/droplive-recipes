FROM ghcr.io/mlflow/mlflow@sha256:9f9276e57cda1593cfa0fe8519145cd49328e119e85951851b9244e82e3769be

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/mlflow/mlflow" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

WORKDIR /mlflow
CMD ["mlflow", "server", "--host", "0.0.0.0", "--port", "5000"]

EXPOSE 5000
