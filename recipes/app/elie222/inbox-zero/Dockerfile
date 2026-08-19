# syntax=docker/dockerfile:1
# Inbox Zero — the reference case for the emulation layer.
#
# Every third-party dependency on its critical path is CONFIG tier, because the app
# ships its own emulator switches: GOOGLE_BASE_URL, MICROSOFT_BASE_URL,
# OPENAI_COMPATIBLE_BASE_URL. Nothing here is intercepted and nothing is
# impersonated — the app is told where to look and looks there.
#
# Pinned to the immutable linux/amd64 child manifest. Upstream publishes only a
# `latest` tag with `org.opencontainers.image.version=latest`, so there is no
# upstream semver to carry; the digest is the pin and the revision below is the
# source identity a launch re-verifies.
FROM ghcr.io/elie222/inbox-zero@sha256:b543689db188d252b7032327129f9f019c0d3257a4febff7a98005cd9318ec14

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256

LABEL org.opencontainers.image.revision="914cad678bd16973cf6c6a773642e79254ced99f" \
      org.opencontainers.image.source="https://github.com/elie222/inbox-zero" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# Static configuration only — every value here is the same for every session.
# Anything per-session arrives as environment at launch and is mapped by the
# entrypoint.
#
# QUEUE_BACKEND=internal avoids QStash entirely: the alternative needs an
# externally reachable callback URL and a signing key pair, neither of which a
# fifteen-minute private demo has.
#
# The analytics variables are deliberately ABSENT rather than set to a placeholder.
# An unset key disables the client; a placeholder makes it try, fail, and put a
# destination on the receipt that describes our configuration rather than the
# software.
ENV NODE_ENV=production \
    PORT=3000 \
    HOSTNAME=0.0.0.0 \
    QUEUE_BACKEND=internal \
    NEXT_PUBLIC_BYPASS_PREMIUM_CHECKS=true \
    NEXT_PUBLIC_DISABLE_PWA=true

WORKDIR /app
EXPOSE 3000

# The readiness contract, and it is the DEEP check on purpose.
#
# `/api/health` answers two different questions. With no `x-health-api-key` header
# it returns `{"status":"ok"}` WITHOUT touching the database — an ALB-style
# liveness ping. With the header it runs `SELECT 1` and answers
# `{"status":"healthy"}`, or 503 when the database is unreachable.
#
# Readiness must be the second. Upstream's start script runs Prisma migrations
# before the server, so a shallow 2xx can pass while the schema is still arriving,
# and traffic would reach an app whose first query fails. This is the same reason
# Rallly's recipe asserts `"database":"connected"` rather than a bare 200.
#
# The header value is read from the env so both configurations work: when
# HEALTH_API_KEY is unset the route falls through to the deep check regardless of
# what was sent, and when the platform generates one, the same value goes back —
# a hardcoded string would 401 against a generated key and fail readiness at
# launch rather than at build.
# State lives in the Postgres companion, not on a volume, and saying so is the
# point: the adapter is a declared contract rather than something inferred from
# the absence of a VOLUME.
LABEL io.droplive.data-backup=postgresql

LABEL io.droplive.readiness.contains.status='"status":"healthy"'

HEALTHCHECK --start-period=90s --interval=15s --timeout=10s --retries=8   CMD ["node", "-e", "fetch('http://127.0.0.1:3000/api/health', {headers: {'x-health-api-key': process.env.HEALTH_API_KEY || 'droplive-readiness'}}).then(async r => { const b = await r.json(); if (!r.ok || b.status !== 'healthy') process.exit(1); }).catch(() => process.exit(1))"]

COPY --chmod=0755 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint.sh

# ENTRYPOINT, not CMD, and that is not style.
#
# `automatic_artifact.py` reads the ENTRYPOINT argv, resolves which locally COPYd
# file it names, and scans THAT script for the `${VAR:?…}` guards that tell the
# brain a value is required. Leaving this as CMD inherits the base image's
# `ENTRYPOINT ["docker-entrypoint.sh"]`, which was never COPYd here — so the
# scanner finds nothing, every guard below is inert, and the five secrets this app
# cannot start without may never be minted. The failure would appear at launch as
# an app exiting on a blank AUTH_SECRET.
#
# Upstream's own start script still runs the Prisma migrations before the server;
# the entrypoint execs the base entrypoint and that script explicitly, so nothing
# in the upstream chain is skipped and readiness cannot pass before the schema
# exists.
ENTRYPOINT ["/usr/local/bin/droplive-entrypoint.sh"]
