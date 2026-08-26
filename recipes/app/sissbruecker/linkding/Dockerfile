FROM docker.io/sissbruecker/linkding@sha256:0c0a9a04c7ebd644293c37f98710872fe7cdff0ea1ff7fd9be4d235e4c4678d2

COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-linkding-entrypoint

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/sissbruecker/linkding" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# linkding has no default account: it creates the superuser at boot from these
# two, and creates nobody without them. A visitor met a sign-in page with a
# credential nobody had told them and no way to make one.
#
# Only the password is a secret, and DropLive mints it per demo (see
# droplive.yaml). The username is the reviewed world identity, so OIDC finds
# this same account and the seeded bookmarks are visible after Maya signs in.
ENV LD_SUPERUSER_NAME=maya@northstar-relay.droplive.test

# Off in the image, on because the demo has an issuer to point at. A sign-in
# button that leads nowhere is worse than no button.
ENV LD_ENABLE_OIDC=True

# Stated rather than left to the default, because it is the assertion the whole
# fixture rests on: the emulator mints RS256 id tokens and serves a real JWKS, and
# linkding's client verifies the signature against it. A silent default is not a
# claim. (At the pinned emulate version Google signs HS256 with a hardcoded secret
# and serves an empty key set, which is why these endpoints are Microsoft's.)
ENV OIDC_RP_SIGN_ALGO=RS256

# The base image owns migrations and the initial superuser. The wrapper waits for
# that normal startup, then writes a sizeable, session-local bookmark set for a
# disposable demo. It is gated by DROPLIVE_DEMO and a data-volume marker, so a
# persistent deployment is never overwritten.
ENTRYPOINT ["/usr/local/bin/droplive-linkding-entrypoint"]

EXPOSE 9090
