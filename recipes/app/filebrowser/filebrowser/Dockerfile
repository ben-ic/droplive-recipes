FROM docker.io/filebrowser/filebrowser@sha256:593478e3c24c5ea9f5d7478dc549965b7bc7030707291006ce8d0b6162d3454b

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# The company's shared drive. COPY keeps each file's modification time from the
# build context, and those are the dates the world gives them, so the column a
# file manager sorts by is not twenty identical build timestamps. Directory dates
# are the entrypoint's job -- see there for why.
COPY seed/srv/ /srv/

COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-filebrowser

EXPOSE 80

# The upstream binary becomes the command, so the setup runs before the real
# startup rather than replacing it.
ENTRYPOINT ["/usr/local/bin/droplive-filebrowser"]
CMD ["/filebrowser"]
