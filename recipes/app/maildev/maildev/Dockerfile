FROM docker.io/maildev/maildev@sha256:ad6d46b7c47617c141961649a9ed5e50069aed53e94ca5359a59b3e1459925da

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

USER root
# A year of the Northstar company's mail, one RFC 822 file per message, and the
# SMTP conversation that delivers it.
# A directory copied with an explicit mode loses its execute bit, and then a
# non-root process cannot read anything inside it. The generated tree is already
# 0644 files in 0755 directories.
COPY seed/mail/ /usr/local/lib/droplive-maildev-mail/
COPY --chmod=0444 droplive-seed.js /usr/local/lib/droplive-maildev-seed.js
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-maildev
USER node

EXPOSE 1080

# The upstream command becomes the command, so the seeder wraps the real startup
# rather than replacing it.
ENTRYPOINT ["/usr/local/bin/droplive-maildev"]
CMD ["node", "dist/bin/maildev.js"]
