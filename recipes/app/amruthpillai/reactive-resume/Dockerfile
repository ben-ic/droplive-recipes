# Reactive Resume v5.2.5 official linux/amd64 image, pinned immutably.
FROM docker.io/amruthpillai/reactive-resume@sha256:0f6f602d530a6724a9619d5c784bf8c01abb65a62989b3137f90f268be11857e

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.droplive.source.commit="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}" \
      org.droplive.runtime.contract="reactive-resume-5.2.5"

LABEL org.opencontainers.image.version="5.2.5" \
      org.opencontainers.image.revision="ae8d48bcee400a91c1a0bd2e21be7851977286e6" \
      org.opencontainers.image.source="https://github.com/AmruthPillai/Reactive-Resume" \
      org.opencontainers.image.licenses="MIT" \
      io.droplive.readiness.contains.status="\"status\":\"healthy\""

LABEL io.droplive.data-backup=files

# Reactive Resume's official image already runs as the unprivileged `node`
# user.  DropLive supplies APP_URL, DATABASE_URL, and AUTH_SECRET at runtime;
# the local storage path remains inside the managed app volume.
ENV NODE_ENV=production \
    PORT=3000 \
    LOCAL_STORAGE_PATH=/app/data

WORKDIR /app
USER node
VOLUME ["/app/data"]
EXPOSE 3000

# The application health response checks both PostgreSQL and local storage.
# Require all three typed statuses instead of accepting an arbitrary 2xx page.
HEALTHCHECK --start-period=60s --interval=30s --timeout=10s --retries=4 \
  CMD node -e "fetch('http://127.0.0.1:3000/api/health').then(async r => { const b = await r.json(); if (!r.ok || b.status !== 'healthy' || b.database?.status !== 'healthy' || b.storage?.status !== 'healthy') process.exit(1); }).catch(() => process.exit(1))"

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["node", "apps/server/dist/index.mjs"]
