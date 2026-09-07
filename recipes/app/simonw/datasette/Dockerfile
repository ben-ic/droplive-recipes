# WorldFixture 0.2.5 supplies the reviewed data at build time only.
FROM ghcr.io/ben-ic/worldfixture@sha256:de90b87caba05396b7570807fed2ae50d85e0f82ab302cfabc8ad1ed21d9d41e AS world

FROM docker.io/datasetteproject/datasette@sha256:0f57db16cf4eb6cca57f1cedaa0a696bca1c65a1d75b8f7ee372c2dd909a32a0

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/simonw/datasette" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# Build from verified neutral packs with the Python already in Datasette.
# No WorldFixture service or application data runs outside the session.
COPY --from=world /opt/worldfixture/dist/business.saas-company.v3/manifest.json /tmp/worldfixture/manifest.json
COPY --from=world /opt/worldfixture/dist/business.saas-company.v3/packs /tmp/worldfixture/packs
COPY --from=world /usr/share/licenses/worldfixture/LICENSE /usr/share/licenses/worldfixture/LICENSE
COPY seed/WORLDFIXTURE-NOTICE /usr/share/licenses/worldfixture/NOTICE
COPY seed/worldfixture.py /tmp/worldfixture.py
COPY --chmod=0444 seed/metadata.json /usr/local/lib/droplive-datasette-metadata.json
RUN python3 /tmp/worldfixture.py /tmp/worldfixture /usr/local/lib/northstar.db \
    && rm -rf /tmp/worldfixture /tmp/worldfixture.py \
    && chmod 0444 /usr/local/lib/northstar.db

EXPOSE 8001

# The image's own command binds Uvicorn to 127.0.0.1, so nothing outside the
# container can reach it: "Uvicorn running on http://127.0.0.1:8001". Serve on
# all interfaces instead, and open the demo on the company rather than on an
# empty instance the visitor has to find data for.
#
# --immutable is the honest declaration: the file is read-only, and it lets
# Datasette cache row counts for the fixed snapshot.
CMD ["datasette", "serve", "--host", "0.0.0.0", "--port", "8001", \
     "--metadata", "/usr/local/lib/droplive-datasette-metadata.json", \
     "--immutable", "/usr/local/lib/northstar.db"]
