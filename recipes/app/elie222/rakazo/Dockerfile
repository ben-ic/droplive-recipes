FROM node:22-bookworm@sha256:0557ac14e0d45d02ed563067b82856ca5e7aa3437fa28d98d4350ea9c3d9494a AS build

RUN corepack enable
WORKDIR /app

ADD --checksum=sha256:eaa313e23d2606d517a8cfa4320685853fc9bdaaf62a20ec0b308c15c7609ace \
  https://github.com/elie222/rakazo/archive/90572cb2bcab4458aebbe1994b3ffbc9ddfac339.tar.gz /tmp/rakazo.tar.gz
RUN tar -xzf /tmp/rakazo.tar.gz --strip-components=1 \
  && rm /tmp/rakazo.tar.gz

COPY droplive-openrouter-base-url.patch /tmp/droplive-openrouter-base-url.patch
RUN patch --fuzz=0 -p1 < /tmp/droplive-openrouter-base-url.patch \
  && rm /tmp/droplive-openrouter-base-url.patch \
  && pnpm install --frozen-lockfile=false \
  && pnpm --filter @rakazo/db generate \
  && RAKAZO_ALLOW_DEV_SECRETS=1 pnpm --filter @rakazo/web build \
  && rm -rf /app/apps/desktop /app/apps/mobile /app/apps/www /app/docs \
    /app/infra /app/packages/testkit

FROM node:22-bookworm@sha256:0557ac14e0d45d02ed563067b82856ca5e7aa3437fa28d98d4350ea9c3d9494a

RUN corepack enable
WORKDIR /app
COPY --from=build --chown=node:node /app /app
COPY --from=build --chown=node:node /root/.cache/node/corepack /home/node/.cache/node/corepack
RUN install -d -m 750 -o node -g node /data /app/apps/web/node_modules/.vite-temp

COPY --chmod=755 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256

ENV NODE_ENV=production \
    DATA_DIR=/data \
    SANDBOX_PROVIDER=daytona \
    AGENT_RUNTIME=pi \
    WAKEUP_DRIVER=graphile \
    SIGNUPS_ENABLED=true

USER node
EXPOSE 5173
ENTRYPOINT ["/usr/local/bin/droplive-entrypoint"]
