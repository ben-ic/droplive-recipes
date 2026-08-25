FROM ghcr.io/plankanban/planka@sha256:125f45330853210c678fed1132bedc0912b4a11a27779b79802fbca108e069e2 AS upstream

# Planka declares /app/data a volume. DropLive gives a session one private
# writable root and does not do Docker's copy-up, so a declared volume arrives
# as an empty mount rather than as the directory the image describes. Creating
# it in a stage and then flattening the result leaves a real directory in the
# root the session actually boots.
FROM upstream AS prepared
USER root
RUN mkdir -p /app/data && chown -R node:node /app/data

FROM scratch
COPY --from=prepared / /
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    NODE_VERSION=24.19.0 \
    YARN_VERSION=1.22.22
WORKDIR /app
USER node

# Who the administrator Planka makes at startup is. Only the password is minted
# per session, and it is declared in the recipe rather than written here.
ENV DEFAULT_ADMIN_EMAIL=maya@northstar-relay.droplive.test \
    DEFAULT_ADMIN_NAME="Maya Chen" \
    DEFAULT_ADMIN_USERNAME=maya

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/plankanban/planka" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# The company's four boards, and the runner that plays them in.
COPY --chmod=0444 seed/planka.jsonl /usr/local/lib/droplive-planka-seed.jsonl
COPY --chmod=0444 seed/run.js /usr/local/lib/droplive-planka-seed.js
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-planka

EXPOSE 1337

# The upstream pair becomes the command, so the seeder wraps the real startup
# rather than replacing it.
ENTRYPOINT ["/usr/local/bin/droplive-planka"]
CMD ["docker-entrypoint.sh", "./start.sh"]
