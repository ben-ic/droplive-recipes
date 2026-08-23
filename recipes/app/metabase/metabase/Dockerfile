FROM docker.io/metabase/metabase@sha256:12093d9e80d232a74683f2999873148172ba722cdf55a37fbc90d59afb6419a1

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# The application database is the companion Postgres, whose parts the recipe
# binds to MB_DB_HOST and friends. Metabase needs the type named separately, and
# it is the one part of the connection that is not a per-session value.
ENV MB_DB_TYPE=postgres

# Metabase otherwise arrives with an H2 "Sample Database" and an Examples
# collection of its own. A demo of one company reads as one company.
ENV MB_LOAD_SAMPLE_CONTENT=false

# The Northstar company, one complete request per line: the data source, the SQL
# that builds and fills its tables, eleven saved questions, and the dashboard the
# demo opens on.
COPY --chmod=0444 seed/metabase.requests /usr/local/lib/droplive-metabase-seed.requests
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-metabase

EXPOSE 3000

# The upstream launcher becomes the command, so the seeder wraps the real startup
# rather than replacing it.
ENTRYPOINT ["/usr/local/bin/droplive-metabase"]
CMD ["/app/run_metabase.sh"]
