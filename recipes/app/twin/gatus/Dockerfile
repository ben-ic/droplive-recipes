# syntax=docker/dockerfile:1

# The official scratch image has no shell or HTTP client, so build a tiny probe
# with reproducibility-oriented flags. Independent output equality is untested.
FROM docker.io/library/golang@sha256:301db1784c200c7ec221a84672d0bd3ffdcf6c873bc9806482bbe730910924fb AS health-builder
WORKDIR /src
COPY gatus-healthcheck.go .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -buildvcs=false -ldflags="-s -w -buildid=" -o /out/gatus-healthcheck ./gatus-healthcheck.go

# Gatus v5.36.0 official linux/amd64 image manifest.
FROM ghcr.io/twin/gatus@sha256:8df964117ac6a78749ec8cd00039a499268156b874c3a110dc58de7e312c1ab5

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.droplive.source.commit="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}" \
      org.droplive.runtime.contract="gatus-5.36.0"

COPY config.yaml /config/config.yaml
COPY data/ /data/
COPY --from=health-builder --chmod=0555 /out/gatus-healthcheck /gatus-healthcheck

ENV GATUS_CONFIG_PATH=/config/config.yaml \
    PORT=8080

EXPOSE 8080
VOLUME ["/data"]

# config.yaml pins `storage.type: sqlite` at /data/gatus.db, so the managed data
# is a SQLite database and its dump is integrity-checked. Stating it explicitly
# keeps the adapter off an inference that a layout change could silently break.
LABEL io.droplive.data-backup=sqlite

# Preserve the application's semantic health result in the DropLive launch
# contract; a path-only probe would accept an unrelated 200 response.
LABEL io.droplive.readiness.contains.status='"status":"UP"'

HEALTHCHECK --interval=10s --timeout=4s --start-period=5s --retries=6 \
  CMD ["/gatus-healthcheck", "http://127.0.0.1:8080/health"]
