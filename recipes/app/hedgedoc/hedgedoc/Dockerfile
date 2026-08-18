# syntax=docker/dockerfile:1
# HedgeDoc 1.11.1 official linux/amd64 image, pinned to the immutable child
# manifest. The wrapper only maps DropLive's managed DATABASE_URL to HedgeDoc's
# upstream CMD_DB_URL name; it does not copy credentials into the image.
FROM quay.io/hedgedoc/hedgedoc@sha256:69d1dfe3a0c36a67c871c3beeccef747e8c24ea9fd9b686621fae7ece08c1e68

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256

LABEL org.opencontainers.image.version="1.11.1" \
      org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/hedgedoc/hedgedoc" \
      org.opencontainers.image.licenses="AGPL-3.0-only" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"
LABEL io.droplive.data-backup=files
LABEL io.droplive.readiness.contains.ready='"ready":true'

ENV NODE_ENV=production \
    CMD_HOST=0.0.0.0 \
    CMD_PORT=3000 \
    CMD_PROTOCOL_USESSL=true \
    CMD_URL_ADDPORT=false \
    CMD_ALLOW_ANONYMOUS=false \
    CMD_ALLOW_ANONYMOUS_EDITS=false \
    CMD_ALLOW_EMAIL_REGISTER=true \
    CMD_IMAGE_UPLOAD_TYPE=filesystem \
    CMD_ENABLE_UPLOADS=registered \
    CMD_ENABLE_STATS_API=false

COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint.sh
COPY --chmod=0555 droplive-healthcheck.mjs /usr/local/bin/droplive-healthcheck.mjs

WORKDIR /hedgedoc
VOLUME ["/hedgedoc/public/uploads"]
EXPOSE 3000

# The recipe-owned check is intentionally inspectable by DropLive: it names the
# authoritative endpoint and asserts ready=true, rather than relying on the
# inherited image healthcheck (which is not visible in an uploaded Dockerfile).
HEALTHCHECK --start-period=30s --interval=15s --timeout=6s --retries=4 \
  CMD ["node", "/usr/local/bin/droplive-healthcheck.mjs"]

ENTRYPOINT ["/usr/local/bin/droplive-entrypoint.sh"]
CMD ["node", "app.js"]
