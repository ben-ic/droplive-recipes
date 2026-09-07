# syntax=docker/dockerfile:1
FROM docker.io/djmaze/snappymail@sha256:5e3d990438809a8a49f8ac5758db03e858e6e9fc0e369e1f9e474f7664079905 AS upstream
FROM ghcr.io/ben-ic/worldfixture@sha256:de90b87caba05396b7570807fed2ae50d85e0f82ab302cfabc8ad1ed21d9d41e AS worldfixture
# Keep the pinned runtime filesystem, but do not inherit the full emulator's
# exposed ports. This app publishes only its webmail surface.
FROM scratch
COPY --from=worldfixture / /
ENV DEBIAN_FRONTEND=noninteractive NODE_ENV=production
ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.droplive.source.commit="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"
USER root
RUN apt-get update && apt-get install -y --no-install-recommends php8.2-cli php8.2-mbstring php8.2-xml php8.2-curl php8.2-zip && rm -rf /var/lib/apt/lists/*
COPY --from=upstream /snappymail /snappymail
RUN chown -R root:www-data /snappymail && chmod -R g+rX /snappymail
# This disposable mailbox state is about 46 MiB. Keep its many synchronous
# initialization writes in the guest's private 64 MiB shared-memory filesystem.
RUN sed -i 's@/tmp/worldfixture-mail@/dev/shm/worldfixture-mail@g' /usr/local/bin/worldfixture-mail /etc/worldfixture-mail/imapd.conf /etc/worldfixture-mail/cyrus.conf
COPY WORLDFIXTURE-NOTICE /usr/share/licenses/worldfixture/NOTICE
COPY worldfixture-launch.mjs app-setup.mjs /opt/droplive/
COPY setup.php router.php /opt/droplive/
WORKDIR /snappymail
LABEL org.opencontainers.image.source="https://github.com/the-djmaze/snappymail" org.opencontainers.image.version="2.38.2" org.opencontainers.image.licenses="AGPL-3.0-only"
VOLUME ["/data"]
EXPOSE 8888
HEALTHCHECK --start-period=180s --interval=20s --timeout=5s --retries=3 CMD curl -fsS http://127.0.0.1:8888/healthz || exit 1
ENTRYPOINT ["node", "/opt/droplive/worldfixture-launch.mjs"]
CMD []
