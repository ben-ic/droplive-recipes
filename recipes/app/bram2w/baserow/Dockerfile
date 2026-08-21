FROM docker.io/baserow/baserow@sha256:41adb3493379403946a493f30873f743bb65b19b5f387d630ec75f41e25d5b5b

# DropLive mounts /baserow/data from the declared data volume. Baserow cannot
# detect that mount inside the build probe, so disable only its duplicate check.
ENV DISABLE_VOLUME_CHECK=yes

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/bram2w/baserow" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

EXPOSE 80
