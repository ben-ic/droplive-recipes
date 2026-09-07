# syntax=docker/dockerfile:1
FROM ghcr.io/ben-ic/worldfixture@sha256:de90b87caba05396b7570807fed2ae50d85e0f82ab302cfabc8ad1ed21d9d41e AS worldfixture
FROM docker.io/cloudlena/s3manager@sha256:bb2f0198f53c857c554a812c1b913906927048f09c9aa74b97e3020e43a78d64 AS app
FROM docker.io/library/node@sha256:83f487e0a63425e5b4d146fb5e5be574bcbe1b7b843d3ebafdd95eaf7767a7e5
ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.droplive.source.commit="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"
USER root
RUN apt-get update && apt-get install -y --no-install-recommends jq curl wget && rm -rf /var/lib/apt/lists/*
COPY --from=app /usr/src/app/s3manager /usr/local/bin/s3manager
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
WORKDIR /opt/droplive
LABEL org.opencontainers.image.source="https://github.com/cloudlena/s3manager" org.opencontainers.image.licenses="Apache-2.0"
VOLUME ["/data"]
EXPOSE 8080
HEALTHCHECK --start-period=60s --interval=20s --timeout=5s --retries=3 CMD curl -fsS http://127.0.0.1:8080/ || exit 1
ENTRYPOINT ["node", "/opt/droplive/worldfixture-launch.mjs"]
CMD []
