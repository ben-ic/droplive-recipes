FROM lscr.io/linuxserver/sabnzbd@sha256:8fb83ceffaca6b9c0cc8d86b1acb525818fe3ce1e5a5ee9e9dd1227a26dce57d

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/sabnzbd/sabnzbd" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --chmod=0755 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint
COPY --chmod=0755 configure-demo.sh /custom-cont-init.d/90-droplive-sabnzbd

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/droplive-entrypoint"]
