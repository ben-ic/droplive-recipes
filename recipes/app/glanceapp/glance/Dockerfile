# Glance v0.8.5 official linux/amd64 image manifest, pinned immutably.
FROM glanceapp/glance@sha256:abd3a252d538f24afa0759d677d531dedccd4e4239c524202255cf72de80a2be

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.droplive.source.commit="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}" \
      org.droplive.runtime.contract="glance-0.8.5"

LABEL io.droplive.recipe-source="https://github.com/glanceapp/glance/tree/v0.8.5"
LABEL io.droplive.data-backup=files

COPY --chown=root:root --chmod=0644 glance.template.yml /opt/droplive/glance.template.yml
COPY --chown=root:root --chmod=0755 droplive-entrypoint.sh /opt/droplive/droplive-entrypoint.sh

RUN chmod 0755 /opt/droplive && \
    mkdir -p /app/config && \
    chown 65532:65532 /app/config

VOLUME ["/app/config"]
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=5 \
  CMD ["wget", "-q", "-T", "3", "-O", "/dev/null", "http://127.0.0.1:8080/api/healthz"]

USER 65532:65532
ENTRYPOINT ["/opt/droplive/droplive-entrypoint.sh"]
