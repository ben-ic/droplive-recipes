FROM docker.io/metabase/metabase@sha256:12093d9e80d232a74683f2999873148172ba722cdf55a37fbc90d59afb6419a1 AS app
FROM docker.io/library/eclipse-temurin@sha256:eebd356ad7358b7094758e5787a6726f332917cfd56feab6457c56dab895cdbf AS java
FROM ghcr.io/ben-ic/worldfixture@sha256:de90b87caba05396b7570807fed2ae50d85e0f82ab302cfabc8ad1ed21d9d41e AS worldfixture
FROM scratch
COPY --from=worldfixture / /
COPY --from=java /opt/java/openjdk /opt/java/openjdk
COPY --from=app /app/metabase.jar /opt/metabase/metabase.jar
ENV NODE_ENV=production
ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/metabase/metabase" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"
USER root
RUN apt-get update && apt-get install -y --no-install-recommends libfontconfig1 fonts-dejavu-core && rm -rf /var/lib/apt/lists/*
COPY seed/build_postgres.py seed/worldfixture.py seed/queries.json /opt/droplive/seed/
RUN python3 /opt/droplive/seed/build_postgres.py /opt/worldfixture/dist/business.saas-company.v3 /opt/droplive/northstar.sql
COPY WORLDFIXTURE-NOTICE /usr/share/licenses/worldfixture/NOTICE
COPY worldfixture-launch.mjs app-setup.mjs metabase.mjs /opt/droplive/
WORKDIR /opt/metabase
VOLUME /data
EXPOSE 3000
HEALTHCHECK --start-period=120s --interval=15s --timeout=5s --retries=3 CMD ["curl", "-fsS", "http://127.0.0.1:3000/healthz"]
ENTRYPOINT ["node", "/opt/droplive/worldfixture-launch.mjs"]
CMD []
