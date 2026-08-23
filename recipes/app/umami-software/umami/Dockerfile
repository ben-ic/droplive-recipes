FROM ghcr.io/umami-software/umami@sha256:87312d334d009ee67ee0d2fba8fed01435547cc468e452243aef5133a9984d48

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# Forty-five days of traffic to the Northstar site: 2,079 sessions and 5,370
# pageviews, with the export incident visible in them. Every row is written out
# rather than generated at boot, so what the demo shows is reviewable here.
COPY --chmod=0444 seed/umami.sql /usr/local/lib/droplive-umami-seed.sql
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-umami

EXPOSE 3000

# The upstream pair becomes the command, so the seeder wraps the real startup
# rather than replacing it.
ENTRYPOINT ["/usr/local/bin/droplive-umami"]
CMD ["docker-entrypoint.sh", "sh", "scripts/start-docker.sh"]
