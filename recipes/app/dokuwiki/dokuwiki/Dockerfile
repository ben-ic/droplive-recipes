FROM lscr.io/linuxserver/dokuwiki@sha256:69202cbdaf67e901d7ff79e547e0d3ed4438d2a1008c01ed139da876f448853f

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/dokuwiki/dokuwiki" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# The Northstar company as twenty-five pages in DokuWiki's own markup. Kept out of
# the config volume on purpose -- the init script copies them in, see there for
# why -- and installed through the custom-init directory this image documents.
COPY seed/pages/ /usr/local/lib/droplive-dokuwiki-pages/
COPY --chmod=0755 droplive-init.sh /custom-cont-init.d/10-droplive-northstar.sh

EXPOSE 80
