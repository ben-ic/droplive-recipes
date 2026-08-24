FROM docker.io/grafana/grafana@sha256:5781759b3d27734d4d548fcbaf60b1180dbf4290e708f01f292faa6ae764c5e6

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --chown=472:472 provisioning/dashboards/northstar.yaml /etc/grafana/provisioning/dashboards/northstar.yaml
COPY --chown=472:472 dashboards/northstar-relay.json /opt/droplive/northstar-relay.json
COPY --chown=472:472 --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-grafana-entrypoint

VOLUME ["/var/lib/grafana"]
EXPOSE 3000
ENTRYPOINT ["/usr/local/bin/droplive-grafana-entrypoint"]
