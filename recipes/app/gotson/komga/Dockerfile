FROM docker.io/gotson/komga@sha256:6c2a967bbe9acefd05933b2eb498f34afe96a83c6f7f8ab0acb512a1bb3ab50f

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/gotson/komga" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

EXPOSE 25600

COPY droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint.sh
RUN chmod 0755 /usr/local/bin/droplive-entrypoint.sh

ENV KOMGA_ADMIN_EMAIL=admin@example.org
ENTRYPOINT ["/usr/local/bin/droplive-entrypoint.sh"]
