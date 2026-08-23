FROM docker.io/mazzolino/tiddlywiki@sha256:fbccecb15694599c11445b6fe100327da77c87fb91267918e0fbad3398a5f828

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# The image enables HTTP Basic Auth unless PASSWORD is set, including when it
# is set to an empty value. DropLive demos are already private and temporary,
# so open the wiki directly instead of making readiness and users cross a
# second authentication gate.
ENV PASSWORD=""

# The Northstar company as twenty-five linked tiddlers, plus the three
# configuration tiddlers that name the wiki and choose what it opens on. Kept out
# of the volume on purpose -- the entrypoint copies them in, see there for why.
COPY seed/tiddlers/ /usr/local/lib/droplive-tiddlywiki-tiddlers/
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-tiddlywiki

EXPOSE 8080

# The image's own pair becomes the command, so the seeder wraps the real startup
# rather than replacing it.
ENTRYPOINT ["/usr/local/bin/droplive-tiddlywiki"]
CMD ["docker-entrypoint.sh", "/usr/local/bin/init-and-run-wiki"]
