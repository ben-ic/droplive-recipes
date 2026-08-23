FROM docker.io/listmonk/listmonk@sha256:f535d59e14991337a9f2d570273685378ae86b0d7698c3e00da444e3bc205286

# Upstream's Compose contract initializes and upgrades the database before it
# starts the server. Its plain image command does neither. Keep the public
# defaults here and let DropLive bind the private database values and admin
# password from the recipe.
ENV LISTMONK_app__address=0.0.0.0:9000 \
    LISTMONK_db__ssl_mode=disable \
    LISTMONK_ADMIN_USER=admin

# The Northstar mailing lists, one complete request per line: three lists,
# sixteen subscribers who are all real people from the world, and the two
# campaigns that are still drafts because neither has gone out.
COPY --chmod=0444 seed/listmonk.requests /usr/local/lib/droplive-listmonk-seed.requests
COPY --chmod=0755 entrypoint.sh /usr/local/bin/droplive-listmonk
ENTRYPOINT ["/usr/local/bin/droplive-listmonk"]
CMD []

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/knadh/listmonk" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

EXPOSE 9000
