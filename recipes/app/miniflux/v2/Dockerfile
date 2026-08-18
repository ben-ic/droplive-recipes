# Official Miniflux 2.3.3 linux/amd64 image, pinned immutably.
FROM docker.io/miniflux/miniflux@sha256:4c24c30b8b420c77e3d074bfb6d78cfe5d37670f895fa68c09c43cb719b9ab04

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.droplive.source.commit="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}" \
      org.droplive.runtime.contract="miniflux-2.3.3"

LABEL org.opencontainers.image.version="2.3.3" \
      org.opencontainers.image.revision="c4d54f87a81b30aa173fddf05d7ff83ae7da5796" \
      org.opencontainers.image.source="https://github.com/miniflux/v2" \
      org.opencontainers.image.licenses="Apache-2.0"

ENV LISTEN_ADDR=0.0.0.0:8080 \
    RUN_MIGRATIONS=1 \
    CREATE_ADMIN=1 \
    ADMIN_USERNAME=admin \
    HTTPS=1 \
    LOG_LEVEL=info

COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-miniflux-entrypoint
COPY --chmod=0555 healthcheck.sh /usr/local/bin/droplive-miniflux-healthcheck

EXPOSE 8080
HEALTHCHECK --start-period=20s --interval=30s --timeout=5s --retries=4 \
  CMD ["wget", "-qO-", "http://127.0.0.1:8080/readiness"]

# The endpoint returns the exact `OK` body only after Miniflux has completed
# database-aware startup. Keep that semantic assertion in the typed launch
# contract instead of relying on a shallow root 2xx response.
LABEL io.droplive.readiness.contains.ready="OK"

ENTRYPOINT ["/usr/local/bin/droplive-miniflux-entrypoint"]
CMD ["/usr/bin/miniflux"]
