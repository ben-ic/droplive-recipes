FROM docker.io/snipe/snipe-it@sha256:18cc45da877ec5509e1fdb17b492db42e37d3ca3bc89d885d82e9c0ecdae1253

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/snipe/snipe-it" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# Laravel's own contract. The driver and the app mode are public defaults; the
# host, port, database, username and password come from the companion by name,
# and APP_URL is the session origin.
ENV APP_ENV=production \
    APP_DEBUG=false \
    DB_CONNECTION=mysql

EXPOSE 80
