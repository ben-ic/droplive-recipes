# syntax=docker/dockerfile:1

# Gitea v1.26.2 official linux/amd64 image, pinned immutably. A clean final
# stage preserves the exact filesystem while dropping inherited OCI metadata
# for SSH port 22; Automatic must see only the HTTP port this recipe supports.
FROM docker.gitea.com/gitea@sha256:0b35a8706dd0171866ca4b787b53b272a519fff5ba7520ef4bddbe58121411f9 AS upstream

FROM scratch
ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
COPY --from=upstream / /

LABEL org.droplive.source.commit="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}" \
      org.droplive.runtime.contract="gitea-1.26.2"

LABEL org.opencontainers.image.version="1.26.2" \
      org.opencontainers.image.revision="2c749ce548b1da0a52835861a87b888e67842d29" \
      org.opencontainers.image.source="https://github.com/go-gitea/gitea" \
      org.opencontainers.image.licenses="MIT" \
      io.droplive.recipe-modification="SQLite owner bootstrap, HTTPS-only Git transport, and one managed data path"
LABEL io.droplive.data-backup=files

COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint.sh
COPY --chmod=0555 s6-droplive /etc/s6-droplive

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    USER=git \
    HOME=/root \
    GITEA_ADMIN_USERNAME=owner \
    GITEA_ADMIN_EMAIL=owner@local.droplive.test \
    GITEA_CUSTOM=/data/gitea \
    HTTP_PORT=3000 \
    DB_TYPE=sqlite3 \
    DISABLE_SSH=true \
    INSTALL_LOCK=true \
    GITEA__server__START_SSH_SERVER=false \
    GITEA__actions__ENABLED=false \
    GITEA__service__DISABLE_REGISTRATION=true

VOLUME ["/data"]
EXPOSE 3000

HEALTHCHECK --start-period=30s --interval=30s --timeout=5s --retries=3 \
  CMD ["curl", "--fail", "--silent", "--show-error", "http://127.0.0.1:3000/api/healthz"]

ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["/usr/local/bin/droplive-entrypoint.sh"]
