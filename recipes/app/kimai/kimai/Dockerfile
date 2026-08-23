FROM docker.io/kimai/kimai2@sha256:6dfc631996544bb2b7a0a876f5565047c6dc0c2632fa06fe6f3c6c8d0f7350a6

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/kimai/kimai" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# The address of the account the image bootstraps. It is a literal the visitor
# reads off the sign-in card, so the recipe owns it; only the password is minted.
ENV ADMINMAIL=maya@northstar-relay.invalid

# The Northstar company, one complete request per line: the people, the four
# accounts, their projects and activities, and four weeks of timesheets.
COPY --chmod=0444 seed/kimai.requests /usr/local/lib/droplive-kimai-seed.requests
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-kimai

EXPOSE 8001

# The upstream pair becomes the command, so the seeder wraps the real startup
# rather than replacing it.
ENTRYPOINT ["/usr/local/bin/droplive-kimai"]
CMD ["docker-php-entrypoint", "/entrypoint.sh"]
