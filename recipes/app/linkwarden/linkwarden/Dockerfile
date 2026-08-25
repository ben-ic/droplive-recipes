# syntax=docker/dockerfile:1
# Linkwarden v2.14.1 official linux/amd64 image. The digest is the pinned
# platform-specific manifest resolved from the v2.14.1 multi-architecture tag.
FROM ghcr.io/linkwarden/linkwarden@sha256:93a543cca29362849c98e4504a43c65a7222c5a3868da86da9bec364360a8733

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

LABEL org.opencontainers.image.version="2.14.1" \
      org.opencontainers.image.revision="f11387161a875d9730a8bb8295ddf712061a3d9f" \
      org.opencontainers.image.source="https://github.com/linkwarden/linkwarden" \
      org.opencontainers.image.licenses="AGPL-3.0"

# This exact single-pair line is the reviewed DropLive backup adapter marker;
# keeping it separate prevents the deterministic parser from accepting an
# ambiguous multi-label expression as destructive restore policy.
LABEL io.droplive.data-backup=files

# Linkwarden's local archive, screenshot, PDF, and favicon files are written
# below /data/data. PostgreSQL is supplied as a managed DropLive companion;
# its connection URL and credentials are injected at runtime.
ENV NODE_ENV=production \
    PORT=3000 \
    HOSTNAME=0.0.0.0 \
    STORAGE_FOLDER=/data/data \
    NEXT_PUBLIC_DISABLE_REGISTRATION=true \
    NEXT_PUBLIC_CREDENTIALS_ENABLED=true

COPY entrypoint.sh /usr/local/bin/droplive-linkwarden-entrypoint
COPY seed.cjs /usr/local/lib/droplive-linkwarden-seed.cjs
RUN chmod 0755 /usr/local/bin/droplive-linkwarden-entrypoint

VOLUME ["/data/data"]
EXPOSE 3000

# /login is a stable application route and returns 200 before owner creation;
# unlike the root redirect it is a meaningful readiness check for this image.
HEALTHCHECK --start-period=30s --interval=30s --timeout=5s --retries=4 \
  CMD ["/usr/bin/curl", "--silent", "--fail", "http://127.0.0.1:3000/login"]

ENTRYPOINT ["/usr/local/bin/droplive-linkwarden-entrypoint"]
CMD ["sh", "-c", "yarn prisma:deploy && yarn concurrently:start"]
