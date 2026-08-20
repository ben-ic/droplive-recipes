FROM docker.io/healthchecks/healthchecks@sha256:cd7bcd94350818b3944f82eb5995f48bdeab8c8627977578a569ffa73f56f56f

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/healthchecks/healthchecks" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# Django answered the readiness probe with 400: the demo hostname is generated
# per session, so no fixed value can be right here and there is no platform key
# that yields a bare host (only `public_origin`, which is a full URL).
#
# `*` is safe for what this is -- a µVM that lives fifteen minutes, reachable
# only through DropLive's edge on a hostname carrying the session token. The
# header-poisoning ALLOWED_HOSTS defends against needs a victim who will follow a
# link after the session is destroyed.
ENV ALLOWED_HOSTS=*

EXPOSE 8000
