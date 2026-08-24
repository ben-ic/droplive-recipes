FROM docker.io/pawelmalak/flame@sha256:7a5edc859235486a82871eb624f03048e44f603cba42ea3f60dc7cfe60ca6b3f

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/pawelmalak/flame" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-flame-entrypoint
COPY --chmod=0444 seed.js /opt/droplive/flame-seed.js

ENTRYPOINT ["/usr/local/bin/droplive-flame-entrypoint"]
CMD ["sh", "-c", "chown -R node /app/data && node server.js"]
EXPOSE 5005
