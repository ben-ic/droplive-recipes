# syntax=docker/dockerfile:1
# ntfy v2.26.3 official linux/amd64 manifest, pinned immutably.
ARG SOURCE_DATE_EPOCH=1784582622

FROM binwiederhier/ntfy@sha256:97dadc752c23fcd75ee23609dc4d552dea0f98d062adcdf60942ca30974902ad AS recipe-files
ARG SOURCE_DATE_EPOCH
USER root
COPY --chmod=0555 droplive-entrypoint.sh droplive-health.sh /layer/usr/local/bin/
RUN find /layer -exec touch -h -d "@${SOURCE_DATE_EPOCH}" {} +

FROM binwiederhier/ntfy@sha256:97dadc752c23fcd75ee23609dc4d552dea0f98d062adcdf60942ca30974902ad

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256

LABEL org.opencontainers.image.version="2.26.3" \
      org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      io.droplive.recipe-modification="Private first owner, durable SQLite and attachments, and meaningful health" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"
LABEL io.droplive.readiness.contains.health='"healthy":true'

COPY --link --from=recipe-files /layer/ /

ENV NTFY_LISTEN_HTTP=":8080" \
    NTFY_CACHE_FILE="/var/lib/ntfy/cache.db" \
    NTFY_AUTH_FILE="/var/lib/ntfy/auth.db" \
    NTFY_AUTH_DEFAULT_ACCESS="deny-all" \
    NTFY_ENABLE_LOGIN="true" \
    NTFY_REQUIRE_LOGIN="true" \
    NTFY_BEHIND_PROXY="true" \
    NTFY_ATTACHMENT_CACHE_DIR="/var/lib/ntfy/attachments" \
    NTFY_LOG_FORMAT="json" \
    TZ="Etc/UTC"

VOLUME ["/var/lib/ntfy"]

# Stated explicitly so the managed-data adapter is a declared contract rather than
# an inference. The sqlite adapter archives every file under the data dirs and
# additionally requires a readable database, so it is the stronger of the two.
LABEL io.droplive.data-backup=sqlite
EXPOSE 8080

HEALTHCHECK --start-period=10s --interval=30s --timeout=5s --retries=3 \
  CMD ["/usr/local/bin/droplive-health.sh"]

ENTRYPOINT ["/usr/local/bin/droplive-entrypoint.sh"]
