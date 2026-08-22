FROM docker.io/writeas/writefreely@sha256:81cd72cc54bf9549c65b81c6a0f5693cdd066e23879dd9bf51533faf7403bd0e

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/writefreely/writefreely" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

USER root
RUN mkdir -p /writefreely && chown daemon:daemon /writefreely

COPY --chmod=755 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint

USER daemon
ENTRYPOINT ["/usr/local/bin/droplive-entrypoint"]

EXPOSE 8080
