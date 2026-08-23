FROM docker.io/linuxserver/grav@sha256:95afce21fbcd86a92d0db0a7ecba5d22d17d264a77840f6b95dba2eca92d72ac

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# The Northstar company as twenty-five markdown pages. Kept out of the config
# volume on purpose -- the init script copies them in, see there for why -- and
# installed through the custom-init directory this image documents.
COPY seed/pages/ /usr/local/lib/droplive-grav-pages/
COPY --chmod=0755 droplive-init.sh /custom-cont-init.d/10-droplive-northstar.sh

EXPOSE 80
