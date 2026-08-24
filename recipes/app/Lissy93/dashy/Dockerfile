FROM docker.io/lissy93/dashy@sha256:ac0f68a6d83e689e4d9f1a74766223cd32cf3cd70b9a1fff72451f344781f807

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/Lissy93/dashy" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --chown=node:node --chmod=0444 seed/ /opt/droplive/dashy/
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-dashy-entrypoint

USER root
RUN chmod 0755 /opt/droplive /opt/droplive/dashy
USER node

ENTRYPOINT ["/usr/local/bin/droplive-dashy-entrypoint"]
CMD ["node", "server.js"]
EXPOSE 8080
