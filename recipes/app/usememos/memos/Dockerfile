# Memos v0.30.0, official linux/amd64 image manifest.
FROM ghcr.io/usememos/memos@sha256:51a4cef418b1f173ac37139ad99de08da5b8662136007231d3ac8a0498a3095a

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# Repeat the official writable data path explicitly.
VOLUME ["/var/opt/memos"]

# Stated explicitly so the managed-data adapter is a declared contract rather than
# an inference. The sqlite adapter archives every file under the data dirs and
# additionally requires a readable database, so it is the stronger of the two.
LABEL io.droplive.data-backup=sqlite
EXPOSE 5230
