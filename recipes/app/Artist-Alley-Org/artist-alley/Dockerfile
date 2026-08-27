# syntax=docker/dockerfile:1
# Artist Alley's public demo dataset is the project's own version-7 Kaggle
# archive. The checksum pins that release even though Kaggle's download URL
# always resolves the latest public version. The four catalogue files are the
# exact copies used by the v0.10.2 source revision below.
FROM alpine:3.22@sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce AS official-seed

WORKDIR /opt/artist-alley-seed

# Kaggle v7 wraps every media directory in one extra `media/` directory,
# while MANIFEST.json paths start at images/, videos/, audio/, and so on.
# Flatten that wrapper once in the image so the upstream seed command can open
# the real files it selected instead of recording them all as missing.
RUN wget -q -O /tmp/dam-population-seed.zip \
      https://www.kaggle.com/api/v1/datasets/download/mscrnt/dam-population-seed \
    && echo "72b7519ccdab9b7d3c1cc7011c41f42c8b7734e76d19cb06b355433c84e5f55c  /tmp/dam-population-seed.zip" | sha256sum -c - \
    && mkdir -p site catalogue \
    && unzip -q /tmp/dam-population-seed.zip -d site \
    && rm /tmp/dam-population-seed.zip \
    && test -d site/media \
    && mv site/media/* site/ \
    && rmdir site/media \
    && test -f site/MANIFEST.json \
    && test -f site/posts.json \
    && test -f site/ATTRIBUTIONS.md \
    && test -f site/videos/internet/mineclone2-release.webm

RUN for name in \
      dataset.users.json \
      dataset.teams.json \
      dataset.collections.json \
      dataset.field_definitions.json; do \
      wget -q -O "catalogue/$name" \
        "https://raw.githubusercontent.com/Artist-Alley-Org/artist-alley/1c856cb0a6d8bf1dbea4ea570e20d1acaa391839/seed/profiles/$name"; \
    done \
    && echo "9ae255c5a88cb85445c5cc801dc0f7876e93a954ac63272b525c82aa0c5402a0  catalogue/dataset.users.json" | sha256sum -c - \
    && echo "015d242b0b4be5e4670b439a3de10fa2cddf26f9aacd9ad015f62e6c65e582ab  catalogue/dataset.teams.json" | sha256sum -c - \
    && echo "b1aac46d70da1d190b42b6fb0c997220f8e16b6d555af8cd0753e909b4ba7a3e  catalogue/dataset.collections.json" | sha256sum -c - \
    && echo "7c3ed4fd1efb926cb61856f76b3965e25f7de7bea05c5666fb6adbe8e093b74e  catalogue/dataset.field_definitions.json" | sha256sum -c -

# Official v0.10.2 multi-architecture image. Its OCI config identifies source
# revision 1c856cb0a6d8bf1dbea4ea570e20d1acaa391839.
FROM ghcr.io/artist-alley-org/artist-alley@sha256:527962ab113404b99677cde067fcce31d7f82cb42c62aa216629179c61432d85 AS artist-alley

# Keep a coherent raster-art slice of the official catalogue. Video and 3D
# preview work is valuable in a permanent install, but it makes a disposable
# demo wait for several minutes and keeps almost the whole source archive in the
# image. The script selects linked official posts first and asserts a useful
# minimum instead of manufacturing substitute content.
FROM artist-alley AS prepared-seed
COPY --from=official-seed --chown=app:app /opt/artist-alley-seed /tmp/artist-alley-full
COPY --chmod=0444 droplive-prune-seed.mjs /usr/local/lib/droplive-prune-seed.mjs
RUN node /usr/local/lib/droplive-prune-seed.mjs \
      /tmp/artist-alley-full/site /opt/artist-alley-prepared/site \
    && mkdir -p /opt/artist-alley-prepared/catalogue \
    && cp -a /tmp/artist-alley-full/catalogue/. /opt/artist-alley-prepared/catalogue/

# Render the selected assets with Artist Alley's own worker during the build.
# The temporary database and its build-only keys do not enter the final image.
# Only content-addressed derivative files survive; runtime seeding creates a
# fresh database and reconciles its storage_variants rows against these bytes.
FROM artist-alley AS preview-cache
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends postgresql postgresql-client \
    && rm -rf /var/lib/apt/lists/*
USER app
COPY --from=prepared-seed --chown=app:app /opt/artist-alley-prepared /opt/artist-alley-prepared
COPY --chmod=0555 droplive-prebuild-previews.sh /usr/local/bin/droplive-prebuild-previews
RUN /usr/local/bin/droplive-prebuild-previews

FROM artist-alley

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256

LABEL org.opencontainers.image.version="v0.10.2" \
      org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/Artist-Alley-Org/artist-alley" \
      org.opencontainers.image.licenses="AGPL-3.0-only" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

ENV AA_HTTP_ADDR=127.0.0.1:8081 \
    AA_DB_SSLMODE=disable \
    AA_STORAGE_BACKEND=fs \
    AA_STORAGE_FS_ROOT=/var/lib/aa-storage \
    AA_BOOTSTRAP_ADMIN_PATH=/var/lib/aa-storage/bootstrap \
    AA_LOG_LEVEL=info \
    AA_LOG_FORMAT=json

COPY --from=prepared-seed --chown=app:app /opt/artist-alley-prepared /opt/artist-alley-seed
COPY --from=preview-cache --chown=app:app /tmp/droplive-preview-cache /opt/artist-alley-preview-cache
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-artist-alley
COPY --chmod=0444 droplive-feed-ready.mjs /usr/local/lib/droplive-feed-ready.mjs
COPY --chmod=0444 droplive-tcp-proxy.mjs /usr/local/lib/droplive-tcp-proxy.mjs

USER app
WORKDIR /app
VOLUME ["/var/lib/aa-storage"]
LABEL io.droplive.data-backup=files
EXPOSE 8080

HEALTHCHECK --start-period=90s --interval=15s --timeout=5s --retries=8 \
  CMD ["curl", "-fsS", "http://127.0.0.1:8080/healthz"]

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/droplive-artist-alley"]
CMD ["/app/aa"]
