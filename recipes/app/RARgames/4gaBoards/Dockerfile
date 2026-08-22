FROM ghcr.io/rargames/4gaboards@sha256:8968c08275e068aa25cbf604371d458f4b80ad134843f19afd50ea9cc89f3f20

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256

COPY --chmod=0755 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint

EXPOSE 1337

ENTRYPOINT ["/usr/local/bin/droplive-entrypoint"]
