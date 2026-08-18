# Official SiYuan v3.7.3 image, pinned to its linux/amd64 OCI manifest.
FROM b3log/siyuan@sha256:74acc26dbbbddbaa69ce7338bb11b5e5543381d8e00d842e9ea1e2ee0974deb4

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256

LABEL org.opencontainers.image.version="3.7.3" \
      org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/siyuan-note/siyuan" \
      org.opencontainers.image.licenses="AGPL-3.0" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}" \
      io.droplive.data-backup="files" \
      io.droplive.readiness.contains.progress='"progress":100'

# The upstream image sets `WORKDIR /opt/siyuan/`. The run plane requires a
# canonical absolute path. The trailing slash is not canonical. Restating the
# same directory without it changes nothing about where the application runs.
WORKDIR /opt/siyuan

# PUID/PGID are gone because the wrapper no longer runs upstream's entrypoint:
# that script creates the user and group at runtime and chowns three trees, all
# of which write to a root filesystem this run plane mounts read-only. The kernel
# runs as the image's own root inside its isolated microVM.
#
# HOME must be writable and holds nothing worth keeping, so it points at the
# ephemeral /tmp mount rather than at a path under the read-only root.
ENV SIYUAN_WORKSPACE_PATH=/data/siyuan \
    HOME=/tmp/siyuan-home \
    TZ=UTC

COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-siyuan-entrypoint
COPY --chmod=0555 healthcheck.sh /usr/local/bin/droplive-siyuan-healthcheck

RUN mkdir -p /data/siyuan

# The kernel resolves its config directory from the OS user's home rather than
# from $HOME, so running as root it wants /root/.config/siyuan, and the run plane
# mounts the root filesystem read-only. Redirect that one path into the ephemeral
# /tmp mount, the same shape the BentoPDF recipe uses for nginx's cache. Nothing
# under it is meant to outlive the session; the workspace is the persistent path.
RUN rm -rf /root/.config && ln -s /tmp/siyuan-config /root/.config

VOLUME ["/data/siyuan"]
EXPOSE 6806

HEALTHCHECK --start-period=45s --interval=30s --timeout=8s --retries=5 \
  CMD ["/usr/local/bin/droplive-siyuan-healthcheck"]

ENTRYPOINT ["/usr/local/bin/droplive-siyuan-entrypoint"]

# The wrapper prepends /opt/siyuan/kernel and its --workspace flag, so the CMD
# supplies only the subcommand. Upstream's own CMD repeats the binary because its
# entrypoint prepends nothing.
CMD ["serve"]
