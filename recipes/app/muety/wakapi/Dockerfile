FROM busybox@sha256:9db7b59979c38555a39def84a31fb98b5296952f9e3afd4f6f11f05b07adfab0 AS toolbox
RUN mkdir -p /droplive-rootfs && \
    cp -a /lib /droplive-rootfs/lib && \
    ln -s lib /droplive-rootfs/lib64

FROM ghcr.io/muety/wakapi@sha256:b2ed3753af47c5adef330243c2431b04940f2560b57b9dba6029fd851a8f64a9

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --from=toolbox --chown=root:root /droplive-rootfs/lib /lib
COPY --from=toolbox --chown=root:root /droplive-rootfs/lib64 /lib64
COPY --from=toolbox --chown=root:root /bin/busybox /app/busybox
COPY --chown=root:root --chmod=0755 droplive-entrypoint.sh /app/droplive-entrypoint.sh

ENV ENVIRONMENT=prod \
    WAKAPI_DB_TYPE=sqlite3 \
    WAKAPI_DB_NAME=/data/wakapi.db \
    WAKAPI_LISTEN_IPV4=0.0.0.0 \
    WAKAPI_LISTEN_IPV6=- \
    WAKAPI_PORT=3000 \
    WAKAPI_INSECURE_COOKIES=false \
    WAKAPI_ALLOW_SIGNUP=false \
    WAKAPI_OIDC_ALLOW_SIGNUP=false \
    WAKAPI_INVITE_CODES=false \
    WAKAPI_LEADERBOARD_ENABLED=false \
    WAKAPI_MAIL_ENABLED=false

VOLUME ["/data"]

# Stated explicitly so the managed-data adapter is a declared contract rather than
# an inference. The sqlite adapter archives every file under the data dirs and
# additionally requires a readable database, so it is the stronger of the two.
LABEL io.droplive.data-backup=sqlite
LABEL io.droplive.readiness.contains.app='app=1' \
      io.droplive.readiness.contains.db='db=1' \
      org.opencontainers.image.licenses='MIT AND GPL-2.0-only' \
      io.droplive.license-source='/usr/share/doc/droplive-wakapi/BUSYBOX-SOURCE-OFFER.txt'

# BusyBox is GPL-2.0-only. Keep the exact corresponding source and written
# source offer in the immutable runtime image; the helper binary remains
# unchanged from the pinned official image.
COPY --chown=root:root --chmod=0444 licenses/busybox-1.37.0.tar.bz2 \
  /usr/share/doc/droplive-wakapi/busybox-1.37.0.tar.bz2
COPY --chown=root:root --chmod=0444 licenses/BUSYBOX-SOURCE-OFFER.txt \
  /usr/share/doc/droplive-wakapi/BUSYBOX-SOURCE-OFFER.txt
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=5 \
  CMD ["/app/busybox", "sh", "-c", "/app/busybox wget -q -T 3 -O - http://127.0.0.1:3000/api/health | /app/busybox awk 'BEGIN { app=0; db=0 } $0 == \"app=1\" { app=1 } $0 == \"db=1\" { db=1 } END { exit !(app && db) }'"]

USER nonroot
ENTRYPOINT ["/app/droplive-entrypoint.sh"]
