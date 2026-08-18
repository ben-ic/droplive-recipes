# Vaultwarden 1.37.1 official Debian image, pinned to the linux/amd64 manifest.
FROM docker.io/vaultwarden/server@sha256:e9efdf001bf0d68c21f2cbfb8e1d9b5961a7ca9c85e0a7e58bf51a13b997d744

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256

LABEL org.opencontainers.image.version="1.37.1" \
      org.opencontainers.image.revision="2629bcbe1380c894e3a7f52cafcac3988edb8fbb" \
      org.opencontainers.image.source="https://github.com/dani-garcia/vaultwarden" \
      org.opencontainers.image.licenses="AGPL-3.0-only" \
      org.droplive.source.commit="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}" \
      org.droplive.runtime.contract="vaultwarden-1.37.1" \
      io.droplive.recipe-source="https://github.com/dani-garcia/vaultwarden/tree/1.37.1"

# Keep this marker in the exact single-token form consumed by the source
# inspector; quoting the value would silently drop the typed files adapter.
LABEL io.droplive.data-backup=files

# The upstream image already binds 0.0.0.0:80, exposes /data, and ships the
# database-aware /alive health endpoint. These defaults are non-secret runtime
# policy; tenant-specific DOMAIN and the admin token are injected only at run.
ENV DATA_FOLDER=/data/vaultwarden \
    ROCKET_PORT=8080 \
    SIGNUPS_ALLOWED=true \
    SIGNUPS_VERIFY=false \
    INVITATIONS_ALLOWED=false \
    SHOW_PASSWORD_HINT=false \
    ENABLE_WEBSOCKET=true \
    LOG_LEVEL=info

COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-vaultwarden-entrypoint

VOLUME ["/data"]
EXPOSE 8080

# /alive returns a timestamp only after Vaultwarden has opened its configured
# database and launched Rocket; the explicit loopback check keeps this contract
# visible to DropLive's deterministic source planner instead of relying on
# health metadata inherited from the pinned upstream image.
HEALTHCHECK --start-period=30s --interval=30s --timeout=5s --retries=5 \
  CMD ["curl", "--fail", "--silent", "--show-error", "http://127.0.0.1:8080/alive"]

ENTRYPOINT ["/usr/local/bin/droplive-vaultwarden-entrypoint"]
CMD ["/start.sh"]
