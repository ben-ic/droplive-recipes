FROM lscr.io/linuxserver/qbittorrent@sha256:212b86dff59e3962b4082b5ef20a577e76c8f8527d2ab505cfa887b4bcecb0b0

# qBittorrent 4.6.1 and later creates a random temporary WebUI password on
# every fresh start. DropLive users cannot read container logs, so seed the
# upstream configuration with a known demo-only password.
RUN sed -i '/^\[Preferences\]$/a WebUI\\Password_PBKDF2="@ByteArray(ARQ77eY1NUZaQsuDHbIMCA==:0WMRkYTUWVT9wVvdDtHAjU9b3b7uB8NR1Gur2hmQCvCDpm39Q+PsJRJPaCU51dEiz+dTzh8qbPsL8WkFljQYFQ==)"' /defaults/qBittorrent.conf

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/qbittorrent/qBittorrent" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

EXPOSE 8080
