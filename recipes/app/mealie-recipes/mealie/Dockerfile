# Mealie v3.22.0 official linux/amd64 image, pinned immutably.
FROM ghcr.io/mealie-recipes/mealie@sha256:233be76b4cbf8f2d89b11cf689779d6f63c73254cb06815ea37cdeb56c056612

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

LABEL io.droplive.recipe-source="https://github.com/mealie-recipes/mealie/tree/v3.22.0"
LABEL io.droplive.data-backup=files

COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-mealie-entrypoint
COPY --chmod=0444 bootstrap_owner.py /usr/local/lib/droplive-mealie-bootstrap-owner.py
COPY --chmod=0444 seed_recipes.py /usr/local/lib/droplive-mealie-seed-recipes.py

# The official image normally starts as root only to chown /app and then drops
# to uid/gid 911. DropLive owns the fresh managed directory, so make ownership
# deterministic at build time and never grant the application root at runtime.
RUN install -d -o 911 -g 911 -m 0700 /app/data

ENV ALLOW_SIGNUP=false \
    MEALIE_BOOTSTRAP_EMAIL=owner@local.droplive.test \
    TZ=UTC \
    UVICORN_WORKERS=1

VOLUME ["/app/data"]
EXPOSE 9000

# /api/app/about exercises the running API and reads database-backed settings.
HEALTHCHECK --start-period=30s --interval=30s --timeout=5s --retries=4 \
  CMD ["curl", "--fail", "--silent", "--show-error", "http://127.0.0.1:9000/api/app/about"]

USER 911:911
ENTRYPOINT ["/usr/local/bin/droplive-mealie-entrypoint"]
CMD ["mealie"]
