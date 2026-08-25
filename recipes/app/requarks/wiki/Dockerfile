# syntax=docker/dockerfile:1
# Official Wiki.js v2.5.314 linux/amd64 image, rebased only to replace its
# inherited narrow VOLUME metadata with the complete documented writable root.
FROM ghcr.io/requarks/wiki@sha256:160986c6cb6d108269a6362985c17196756c79f682f63111b890a36d77d9d492 AS upstream

FROM scratch
COPY --from=upstream / /
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-wiki-entrypoint

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256

LABEL org.opencontainers.image.version="2.5.314" \
      org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/requarks/wiki" \
      org.opencontainers.image.licenses="AGPL-3.0-only" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# DropLive terminates TLS. Wiki.js receives one managed PostgreSQL companion;
# DB_HOST/PORT/USER/PASS/NAME are derived at runtime, never baked into the image.
ENV DB_TYPE=postgres \
    DB_PORT=5432 \
    DB_SSL=false \
    SSL_ACTIVE=false \
    HA_ACTIVE=false \
    PORT=3000 \
    LOG_LEVEL=info \
    LOG_FORMAT=default

WORKDIR /wiki
USER 1000:1000
VOLUME ["/wiki/data"]

# Wiki.js keeps pages in PostgreSQL, but /wiki/data is its documented writable
# root (local asset/upload storage, sideloaded locales, caches). Without this the
# control plane infers no companion for it at all — a data directory beside a
# database companion is expected to have none — so nothing would attempt the
# capture and no failed row or alert would reveal the gap.
LABEL io.droplive.data-backup=files
EXPOSE 3000

# Root requires a working application/DB path and returns the supported setup
# page before first-owner completion, then the normal Wiki.js UI afterwards.
HEALTHCHECK --start-period=30s --interval=30s --timeout=5s --retries=4 \
  CMD ["node", "-e", "fetch(\"http://127.0.0.1:3000/\").then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"]

ENTRYPOINT ["/usr/local/bin/droplive-wiki-entrypoint"]
CMD ["node", "--no-deprecation", "server"]
