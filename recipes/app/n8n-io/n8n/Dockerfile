FROM docker.io/n8nio/n8n@sha256:14c4285bc3034dc5b51034aea393711d27053588e460722bce523453a626f23c

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --chmod=0555 droplive-entrypoint.mjs /usr/local/bin/droplive-n8n.mjs

ENTRYPOINT ["node", "/usr/local/bin/droplive-n8n.mjs"]
CMD ["/docker-entrypoint.sh"]

EXPOSE 5678
