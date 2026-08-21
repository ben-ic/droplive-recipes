FROM docker.io/linuxserver/calibre-web@sha256:241009026e6fa74238b2cb3fec755c4c64474e94a1e434f5731ed6ca409c8054

ADD --checksum=sha256:fac2f7e37ef4bc0fb2955e9a3f612604707d4ef573af5c28bd7a8369339f4bd4 \
    https://raw.githubusercontent.com/janeczku/calibre-web/0d68aef71d3548cc60758bf716fa3e1214a41f3e/library/metadata.db \
    /opt/droplive/calibre-library/metadata.db

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --chmod=755 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint
COPY --chmod=755 configure-demo.sh /custom-cont-init.d/90-droplive-calibre

EXPOSE 8083

ENTRYPOINT ["/usr/local/bin/droplive-entrypoint"]
