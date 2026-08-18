# Karakeep v0.33.1 official multi-architecture image, pinned immutably.
FROM ghcr.io/karakeep-app/karakeep@sha256:5467873df817ab3aa837f2b06bd7f2b0974132ba1ae5bce0b7e2fd134abc269b

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

LABEL org.opencontainers.image.version="0.33.1" \
      org.opencontainers.image.revision="aa69d1deadd826577d1207fae44621c23d4f2fef" \
      org.opencontainers.image.source="https://github.com/karakeep-app/karakeep" \
      org.opencontainers.image.licenses="AGPL-3.0" \
      io.droplive.data-backup=sqlite

# The AIO image includes Karakeep's web and worker processes. This first
# recipe deliberately uses the supported embedded SQLite topology. Search and
# browser crawling remain disabled until their companion services are supplied.
ENV DATA_DIR=/data \
    PORT=3000 \
    HOSTNAME=0.0.0.0 \
    NEXTAUTH_URL_INTERNAL=http://127.0.0.1:3000 \
    RATE_LIMITING_ENABLED=true \
    DISABLE_NEW_RELEASE_CHECK=true \
    CRAWLER_HEADLESS_BROWSER=false \
    SEMANTIC_SEARCH_ENABLED=false \
    DISABLE_SIGNUPS=false

COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-karakeep-entrypoint

VOLUME ["/data"]
EXPOSE 3000

# The upstream endpoint reports application health as JSON. DropLive also
# retains the exact body assertion below; HTTP 200 on a different path is not
# sufficient to prove readiness.
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=5 \
  CMD ["wget", "--no-verbose", "--tries=1", "--spider", "http://127.0.0.1:3000/api/health"]

LABEL io.droplive.readiness.contains.status='"status":"ok"'

ENTRYPOINT ["/usr/local/bin/droplive-karakeep-entrypoint"]
