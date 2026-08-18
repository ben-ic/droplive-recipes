# syntax=docker/dockerfile:1
# Wallos 5.4.2 official linux/amd64 image, pinned by immutable manifest.
ARG SOURCE_DATE_EPOCH=1784468691

FROM bellamy/wallos@sha256:470e8c0d144c037c1d1faaafc687e51fe40ccb152f104875a54b10574bd221b8 AS recipe-files
ARG SOURCE_DATE_EPOCH
COPY --chmod=0755 droplive-startup.sh droplive-healthcheck.sh \
  droplive-validate-database.sh droplive-cron-run /layer/usr/local/bin/
COPY droplive-cronjobs /layer/usr/local/share/droplive-wallos-crontab
COPY droplive-owner-gate.php /layer/usr/local/share/droplive-owner-gate.php
COPY droplive-owner-setup.php /layer/var/www/html/droplive-owner-setup.php
COPY 99-droplive-owner-gate.ini /layer/usr/local/etc/php/conf.d/99-droplive-owner-gate.ini
RUN find /layer -exec touch -h -d "@${SOURCE_DATE_EPOCH}" {} +

FROM bellamy/wallos@sha256:470e8c0d144c037c1d1faaafc687e51fe40ccb152f104875a54b10574bd221b8

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256

LABEL org.opencontainers.image.version="5.4.2" \
      org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/ellite/Wallos" \
      org.opencontainers.image.licenses="GPL-3.0" \
      io.droplive.recipe-modification="Lifecycle reordered for owner claim, migration gating, durable cron, and meaningful health" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

LABEL io.droplive.data-backup=files

COPY --link --from=recipe-files /layer/ /

ENV TZ="Etc/UTC"

VOLUME ["/var/www/html/db", "/var/www/html/images/uploads/logos"]
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD ["/usr/local/bin/droplive-healthcheck.sh"]

CMD ["/usr/local/bin/droplive-startup.sh"]
