# syntax=docker/dockerfile:1
FROM node:22-bookworm@sha256:0557ac14e0d45d02ed563067b82856ca5e7aa3437fa28d98d4350ea9c3d9494a AS build

WORKDIR /app
RUN corepack enable && corepack prepare pnpm@9.15.9 --activate

ADD --checksum=sha256:c00078a803634d30e7ba661cf6ef1b89bdac1629d916f7c8d32c84868fe8dd0f \
  https://github.com/Telemetry-Tracker/telemetry-tracker/archive/d9853e2e286554fce798301bf6b0c239f9b5126c.tar.gz /tmp/telemetry-tracker.tar.gz
RUN tar -xzf /tmp/telemetry-tracker.tar.gz --strip-components=1 \
  && rm /tmp/telemetry-tracker.tar.gz \
  && pnpm install --frozen-lockfile \
  && pnpm --filter @telemetry-tracker/core build \
  && pnpm --filter @telemetry-tracker/next build \
  && pnpm --filter api build \
  && pnpm --filter dashboard build \
  && rm -rf apps/dashboard/.next/cache

FROM node:22-bookworm@sha256:0557ac14e0d45d02ed563067b82856ca5e7aa3437fa28d98d4350ea9c3d9494a

WORKDIR /app
RUN corepack enable

COPY --from=build --chown=node:node /app /app
COPY --from=build --chown=node:node /root/.cache/node/corepack /home/node/.cache/node/corepack
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-telemetry-tracker
COPY --chown=node:node --chmod=0444 droplive-seed.mjs /app/apps/api/droplive-seed.mjs

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256

LABEL org.opencontainers.image.version="v1.17.5" \
      org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/Telemetry-Tracker/telemetry-tracker" \
      org.opencontainers.image.licenses="MIT" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

ENV NODE_ENV=production \
    COREPACK_HOME=/home/node/.cache/node/corepack \
    HOST=127.0.0.1 \
    PORT=3001 \
    API_URL=http://127.0.0.1:3001 \
    TELEMETRY_ORGANIZATION_ID=51000000-0000-4000-8000-000000000001 \
    TELEMETRY_PROJECT_ID=51000000-0000-4000-8000-000000000100 \
    HEALTH_CHECK_DATABASE=true \
    HEALTH_DETAILED=true \
    TELEMETRY_ALLOW_REGISTRATION=false

USER node
EXPOSE 3000
ENTRYPOINT ["/usr/local/bin/droplive-telemetry-tracker"]
