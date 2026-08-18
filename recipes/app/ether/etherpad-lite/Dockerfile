# Official Etherpad v3.3.3 linux/amd64 image, pinned to the immutable child
# digest. The image is built from the Apache-2.0 release source upstream.
FROM docker.io/etherpad/etherpad@sha256:776e8d66b967c756771f681ae6f887f3ce3e831269728cddb0ab2537e23d1fa8

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.droplive.source.commit="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}" \
      org.droplive.runtime.contract="etherpad-3.3.3"

LABEL org.opencontainers.image.version="3.3.3" \
      org.opencontainers.image.revision="a90e0f191cb97f094a3de0345ab3dbbd440d39c5" \
      org.opencontainers.image.source="https://github.com/ether/etherpad" \
      org.opencontainers.image.licenses="Apache-2.0"
LABEL io.droplive.data-backup=files
LABEL io.droplive.readiness.contains.pass='"status":"pass"'

# The official image keeps Etherpad's production startup command and unprivileged
# etherpad user. DropLive supplies the DB_* and PUBLIC_URL values at runtime.
ENV NODE_ENV=production \
    ETHERPAD_PRODUCTION=true \
    IP=0.0.0.0 \
    PORT=9001 \
    DB_TYPE=postgres \
    DB_PORT=5432 \
    AUTHENTICATION_METHOD=apikey \
    TRUST_PROXY=true \
    REQUIRE_AUTHENTICATION=true \
    PRIVACY_UPDATE_CHECK=false \
    PRIVACY_PLUGIN_CATALOG=false \
    UPDATES_TIER=off \
    DEFAULT_PAD_TEXT="Welcome to your DropLive Etherpad."

WORKDIR /opt/etherpad-lite
VOLUME ["/opt/etherpad-lite/var"]
COPY --chmod=0555 droplive-healthcheck.mjs /usr/local/bin/droplive-healthcheck.mjs
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint.sh

EXPOSE 9001
HEALTHCHECK --start-period=30s --interval=15s --timeout=6s --retries=4 \
  CMD ["node", "/usr/local/bin/droplive-healthcheck.mjs"]

# Retain the official startup command and explicitly point API-key mode at the
# managed data path. Without this flag Etherpad defaults to `./APIKEY.txt` in
# the image workdir, which would be regenerated outside persistent storage.
ENTRYPOINT ["/usr/local/bin/droplive-entrypoint.sh"]
CMD ["sh", "-c", "cd src && exec node --require tsx/cjs node/server.ts --apikey /opt/etherpad-lite/var/APIKEY.txt"]
