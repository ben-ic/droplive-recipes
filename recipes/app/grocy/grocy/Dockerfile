FROM lscr.io/linuxserver/grocy@sha256:35b2c85b1238f8249c9b349fb03619d1915917e61b2e4bff580729ec87397b4c AS upstream

ENV GROCY_DATAPATH=/var/www/grocy-data

# DropLive does not expose low container ports. Keep LinuxServer's production
# Nginx/PHP topology, but terminate TLS at DropLive and listen internally on
# an unprivileged deterministic port.
RUN sed -i \
      -e 's/listen 80 default_server;/listen 8080 default_server;/' \
      -e 's/listen \[::\]:80 default_server;/listen [::]:8080 default_server;/' \
      -e '/listen .*443/d' \
      -e '/include \/config\/nginx\/ssl.conf;/d' \
      /defaults/nginx/site-confs/default.conf.sample

COPY droplive-entrypoint.sh droplive-bootstrap-owner.sh /usr/local/bin/
RUN chmod 0755 \
      /usr/local/bin/droplive-entrypoint.sh \
      /usr/local/bin/droplive-bootstrap-owner.sh \
    && mkdir -p /custom-cont-init.d \
    && cp \
      /usr/local/bin/droplive-bootstrap-owner.sh \
      /custom-cont-init.d/90-droplive-bootstrap-owner

# The LinuxServer base declares /config as a volume. In this exact topology it
# contains only regenerated Nginx/PHP scaffolding, internal TLS keys, logs, and
# an empty crontab tree; Grocy's user state is redirected to GROCY_DATAPATH.
# Rebase the already-mutated, digest-pinned root filesystem so the final OCI
# metadata declares only the authoritative managed data path. This deliberately
# keeps DropLive's unmanaged-volume guard fail-closed.
FROM scratch

COPY --from=upstream / /

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256

# Restate the selected process script in the final stage. Besides preserving
# executable mode explicitly, this gives Automatic an exact, bounded source
# mapping for the fail-closed generated-secret guard after the rootfs rebase.
COPY --chmod=0755 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint.sh

ENV PATH=/lsiopy/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    PS1="$(whoami)@$(hostname):$(pwd)\\$ " \
    HOME=/root \
    TERM=xterm \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_VERBOSITY=1 \
    S6_STAGE2_HOOK=/docker-mods \
    VIRTUAL_ENV=/lsiopy \
    PHP_INI_SCAN_DIR=:/config/php \
    LSIO_FIRST_PARTY=true \
    GROCY_DATAPATH=/var/www/grocy-data

WORKDIR /

LABEL build_version="Linuxserver.io version:- v4.6.0-ls334 Build-date:- 2026-07-26T09:37:45+00:00" \
      maintainer="alex-phillips, homerr" \
      org.opencontainers.image.authors="linuxserver.io" \
      org.opencontainers.image.created="2026-07-26T09:37:45+00:00" \
      org.opencontainers.image.description="Grocy is an open-source ERP system for kitchens and households." \
      org.opencontainers.image.documentation="https://docs.linuxserver.io/images/docker-grocy" \
      org.opencontainers.image.licenses="GPL-3.0-only" \
      org.opencontainers.image.ref.name="5bdbecf3afe8bdf70082da66b01535fbc5896c55" \
      org.opencontainers.image.revision="5bdbecf3afe8bdf70082da66b01535fbc5896c55" \
      org.opencontainers.image.source="https://github.com/linuxserver/docker-grocy" \
      org.opencontainers.image.title="Grocy" \
      org.opencontainers.image.url="https://github.com/linuxserver/docker-grocy/packages" \
      org.opencontainers.image.vendor="linuxserver.io" \
      org.opencontainers.image.version="v4.6.0-ls334"

LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

EXPOSE 8080
VOLUME ["/var/www/grocy-data"]

# Stated explicitly so the managed-data adapter is a declared contract rather than
# an inference. The sqlite adapter archives every file under the data dirs and
# additionally requires a readable database, so it is the stronger of the two.
LABEL io.droplive.data-backup=sqlite

ENTRYPOINT ["/usr/local/bin/droplive-entrypoint.sh"]

HEALTHCHECK --interval=10s --timeout=5s --start-period=45s --retries=6 \
  CMD curl --fail --silent --show-error --output /dev/null http://127.0.0.1:8080/ \
    && test -s /var/www/grocy-data/grocy.db \
    || exit 1
