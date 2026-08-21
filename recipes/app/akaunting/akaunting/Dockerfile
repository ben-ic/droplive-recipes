FROM docker.io/akaunting/akaunting@sha256:50940112be48a229a2f567dc50ace9886fe5b14e1fe33f0232e704d0fb96f29f

ENV AKAUNTING_SETUP=true \
    LOCALE=en-US \
    DB_CONNECTION=mysql \
    DB_PREFIX=dl_ \
    COMPANY_NAME="DropLive Demo" \
    COMPANY_EMAIL=demo@example.invalid \
    ADMIN_EMAIL=admin@example.invalid

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/akaunting/akaunting" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --chmod=755 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/droplive-entrypoint"]
CMD ["--start"]
