FROM docker.io/netdata/netdata@sha256:c45c71eb23ff3f1012bcda7832bf08c0b09954363557e84511bcfaf6cafa3aa8

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/netdata/netdata" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --chown=netdata:netdata netdata.conf /etc/netdata/netdata.conf

EXPOSE 19999
