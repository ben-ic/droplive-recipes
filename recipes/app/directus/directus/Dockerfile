FROM docker.io/directus/directus@sha256:8468342b0ca17a4163519731510f327b53d56315f45838d1e78b69e4894d8243

# Directus uses these at its first bootstrap. The password, encryption key and
# token secret come from the recipe contract below; this address is synthetic
# fixture data and is safe to show on the demo card.
ENV ADMIN_EMAIL=maya@northstar-relay.example.com

COPY --chmod=0555 droplive-entrypoint.mjs /usr/local/bin/droplive-directus.mjs

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

EXPOSE 8055

ENTRYPOINT ["node", "/usr/local/bin/droplive-directus.mjs"]
CMD ["/bin/sh", "-c", ": && node cli.js bootstrap && pm2-runtime start ecosystem.config.cjs"]
