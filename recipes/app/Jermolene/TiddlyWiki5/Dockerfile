FROM docker.io/mazzolino/tiddlywiki@sha256:fbccecb15694599c11445b6fe100327da77c87fb91267918e0fbad3398a5f828

# The image enables HTTP Basic Auth unless PASSWORD is set, including when it
# is set to an empty value. DropLive demos are already private and temporary,
# so open the wiki directly instead of making readiness and users cross a
# second authentication gate.
ENV PASSWORD=""

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/Jermolene/TiddlyWiki5" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

EXPOSE 8080
