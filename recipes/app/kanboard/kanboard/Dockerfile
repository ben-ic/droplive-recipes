FROM docker.io/kanboard/kanboard@sha256:064004e1582ee54dc0821e74cc33653b9c547b3faafafa2616e84ac27826ba2e

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# The Northstar boards, one complete JSON-RPC request body per line. Read by the
# entrypoint and posted to Kanboard's own API, so nothing here writes to SQLite.
COPY --chmod=0444 seed/kanboard.jsonl /usr/local/lib/droplive-kanboard-seed.jsonl
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-kanboard

EXPOSE 80

# The upstream entrypoint becomes the command, so the seeder wraps the real
# startup rather than replacing it.
ENTRYPOINT ["/usr/local/bin/droplive-kanboard"]
CMD ["/usr/local/bin/entrypoint.sh"]
