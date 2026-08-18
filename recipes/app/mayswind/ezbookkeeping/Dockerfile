# syntax=docker/dockerfile:1
# ezBookkeeping v1.6.1, official linux/amd64 image manifest.
ARG SOURCE_DATE_EPOCH=1784554891
FROM mayswind/ezbookkeeping@sha256:1bd6520d9645e906955760c82abe2b897221ec0389bc5158e739baca34cd218e
ARG SOURCE_DATE_EPOCH
ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256

LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}" \
      org.droplive.runtime.contract="ezbookkeeping-v1.6.1"

# Preserve upstream's UID/GID 1000 runtime while making its pre-existing-path
# requirement explicit and idempotent. DropLive managed volumes are writable but
# intentionally empty, unlike Docker's named-volume copy-up behavior.
COPY --chown=1000:1000 data/ /data/
COPY --chown=1000:1000 --chmod=0555 droplive-entrypoint.sh /droplive-entrypoint.sh

# Use upstream-supported environment overrides to keep all durable SQLite and
# attachment state in one platform-managed path. Keep logs on stdout/stderr.
ENV EBK_DATABASE_DB_PATH=/data/ezbookkeeping.db \
    EBK_STORAGE_LOCAL_FILESYSTEM_PATH=/data/storage \
    EBK_LOG_MODE=console

VOLUME ["/data"]

# Stated explicitly so the managed-data adapter is a declared contract rather than
# an inference. The sqlite adapter archives every file under the data dirs and
# additionally requires a readable database, so it is the stronger of the two.
LABEL io.droplive.data-backup=sqlite

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -q -O - http://127.0.0.1:8080/healthz.json >/dev/null || exit 1

ENTRYPOINT ["/droplive-entrypoint.sh"]
