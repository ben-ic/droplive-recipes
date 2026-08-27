# syntax=docker/dockerfile:1
# Official v0.10.2 multi-architecture image. Its OCI config identifies source
# revision 1c856cb0a6d8bf1dbea4ea570e20d1acaa391839.
FROM ghcr.io/artist-alley-org/artist-alley@sha256:527962ab113404b99677cde067fcce31d7f82cb42c62aa216629179c61432d85

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256

LABEL org.opencontainers.image.version="v0.10.2" \
      org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/Artist-Alley-Org/artist-alley" \
      org.opencontainers.image.licenses="AGPL-3.0-only" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

ENV AA_HTTP_ADDR=:8080 \
    AA_DB_SSLMODE=disable \
    AA_STORAGE_BACKEND=fs \
    AA_STORAGE_FS_ROOT=/var/lib/aa-storage \
    AA_BOOTSTRAP_ADMIN_PATH=/var/lib/aa-storage/bootstrap \
    AA_LOG_LEVEL=info \
    AA_LOG_FORMAT=json

COPY --chmod=0555 generate-demo.mjs /opt/droplive/generate-demo.mjs
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-artist-alley

USER app
WORKDIR /app
VOLUME ["/var/lib/aa-storage"]
LABEL io.droplive.data-backup=files
EXPOSE 8080

HEALTHCHECK --start-period=90s --interval=15s --timeout=5s --retries=8 \
  CMD ["curl", "-fsS", "http://127.0.0.1:8080/healthz"]

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/droplive-artist-alley"]
CMD ["/app/aa"]
