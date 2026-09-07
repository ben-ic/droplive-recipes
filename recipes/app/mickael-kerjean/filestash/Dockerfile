# syntax=docker/dockerfile:1
FROM ghcr.io/ben-ic/worldfixture@sha256:de90b87caba05396b7570807fed2ae50d85e0f82ab302cfabc8ad1ed21d9d41e AS worldfixture
FROM docker.io/machines/filestash@sha256:edb76ccdfeec1e512b40045f531bb3ceb2c0808960609c7f17ab356dd71b0626
ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.droplive.source.commit="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"
USER root
RUN apt-get update && apt-get install -y --no-install-recommends jq curl wget && rm -rf /var/lib/apt/lists/*
COPY --from=worldfixture /usr/local/bin/node /usr/local/bin/node
COPY --from=worldfixture /opt/worldfixture/runtime /opt/worldfixture/runtime
COPY --from=worldfixture /opt/worldfixture/emulators /opt/worldfixture/emulators
COPY --from=worldfixture /opt/worldfixture/schemas /opt/worldfixture/schemas
COPY --from=worldfixture /opt/worldfixture/dist/business.saas-company.v3 /opt/worldfixture/dist/business.saas-company.v3
COPY --from=worldfixture /usr/bin/weed /usr/bin/weed
COPY --from=worldfixture /usr/local/bin/worldfixture-s3 /usr/local/bin/worldfixture-s3
COPY --from=worldfixture /etc/seaweedfs /etc/seaweedfs
COPY --from=worldfixture /usr/share/licenses/worldfixture /usr/share/licenses/worldfixture
COPY WORLDFIXTURE-NOTICE /usr/share/licenses/worldfixture/NOTICE
COPY worldfixture-launch.mjs app-setup.mjs /opt/droplive/
WORKDIR /app
LABEL org.opencontainers.image.source="https://github.com/mickael-kerjean/filestash" org.opencontainers.image.licenses="AGPL-3.0-only"
VOLUME ["/data"]
EXPOSE 8334
HEALTHCHECK --start-period=60s --interval=20s --timeout=5s --retries=3 CMD curl -fsS http://127.0.0.1:8334/healthz || exit 1
ENTRYPOINT ["node", "/opt/droplive/worldfixture-launch.mjs"]
CMD []
