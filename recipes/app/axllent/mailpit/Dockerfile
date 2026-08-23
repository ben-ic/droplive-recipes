FROM docker.io/axllent/mailpit@sha256:81370195cd4a0eab9604d17c2617a7525b0486f9365555253b6c5376c6350f1a

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# A year of the Northstar company's mail, one RFC 822 file per message, handed to
# Mailpit's own ingest command over SMTP.
# A directory copied with an explicit mode loses its execute bit, and then a
# non-root process cannot read anything inside it. The generated tree is already
# 0644 files in 0755 directories.
COPY seed/mail/ /usr/local/lib/droplive-mailpit-mail/
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-mailpit

EXPOSE 8025

# The upstream binary becomes the command, so the seeder wraps the real startup
# rather than replacing it.
ENTRYPOINT ["/usr/local/bin/droplive-mailpit"]
# --use-message-dates is what makes a year of mail read as a year: without it
# every message is stamped the second it was ingested.
CMD ["/mailpit", "--use-message-dates"]
