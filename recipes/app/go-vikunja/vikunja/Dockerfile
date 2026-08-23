# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# Vikunja v2.4.0 official linux/amd64 image manifest.
ARG SOURCE_DATE_EPOCH=1784481764

FROM vikunja/vikunja@sha256:b0ebd2242e1282e9d4351bdfa0b077f1cffbcfd09c380411a0eb46cd9651e901 AS upstream

# The company's four boards, played into a database here rather than at boot.
#
# Vikunja will not accept a creation date by any route it offers: the task API
# ignores one, and so does its own file migrator, which stamps every imported
# task with the moment of the import. A board whose every task and comment was
# written seconds ago is the one thing a worked-in board never looks like, so
# the seed runs against a real Vikunja in this stage, the two date columns are
# corrected directly, and the finished database is copied out. The running image
# gains nothing from this: no HTTP client, no interpreter, no database tool.
#
# Note that these dates are fixed when the image is built. Vikunja gives no way
# to move them afterwards without adding a database tool to the runtime image,
# so a version that sits in the catalogue for months will show a story that has
# aged. Everything else about the board stays true.
FROM alpine@sha256:d9e853e87e55526f6b2917df91a2115c36dd7c696a35be12163d44e6e2a4b6bc AS seeded
RUN apk add --no-cache python3 sqlite
COPY --from=upstream /app/vikunja/vikunja /app/vikunja/vikunja
COPY seed/run.py seed/build.sh /seed/
COPY seed/vikunja.jsonl /seed/vikunja.jsonl
RUN sh /seed/build.sh

FROM busybox@sha256:29989570aeecad61a019f684218ea74d4b8c1c74f9e0abeb34ca926b81174ee1 AS recipe-files
ARG SOURCE_DATE_EPOCH
USER root
RUN mkdir -p /layer/bin /layer/data/files /layer/usr/local/bin && \
    cp /bin/busybox /layer/bin/busybox && \
    ln -s busybox /layer/bin/sh && \
    ln -s busybox /layer/bin/grep && \
    ln -s busybox /layer/bin/mkdir && \
    ln -s busybox /layer/bin/rm && \
    ln -s busybox /layer/bin/touch && \
    ln -s busybox /layer/bin/cp && \
    ln -s busybox /layer/bin/test && \
    chown -R 1000:1000 /layer/data
COPY --chmod=0555 droplive-entrypoint.sh droplive-health.sh /layer/usr/local/bin/
RUN find /layer -exec touch -h -d "@${SOURCE_DATE_EPOCH}" {} +

FROM vikunja/vikunja@sha256:b0ebd2242e1282e9d4351bdfa0b077f1cffbcfd09c380411a0eb46cd9651e901

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.droplive.source.commit="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}" \
      org.droplive.runtime.contract="vikunja-2.4.0"

COPY --link --from=recipe-files /layer/ /
# No --chmod here. This copy creates /usr/local/lib on the way, and a mode
# meant for a file takes the traverse bit off the directory, which makes the
# file unreachable rather than unwritable.
COPY --link --from=seeded --chown=1000:1000 /build/vikunja.db /usr/local/lib/droplive-vikunja.db

# Keep SQLite and every user-uploaded attachment inside one managed boundary.
# The entrypoint creates the files subdirectory because a managed block volume
# may mount empty instead of applying Docker's named-volume copy-up semantics.
# Local registration is closed because the demo has exactly the accounts the
# seed gave it.
ENV VIKUNJA_DATABASE_TYPE=sqlite \
    VIKUNJA_DATABASE_PATH=/data/vikunja.db \
    VIKUNJA_FILES_TYPE=local \
    VIKUNJA_FILES_BASEPATH=/data/files \
    VIKUNJA_SERVICE_ENABLEREGISTRATION=false \
    VIKUNJA_MAILER_ENABLED=false \
    VIKUNJA_SERVICE_ENABLEEMAILREMINDERS=false

VOLUME ["/data"]

# Stated explicitly so the managed-data adapter is a declared contract rather than
# an inference. The sqlite adapter archives every file under the data dirs and
# additionally requires a readable database, so it is the stronger of the two.
LABEL io.droplive.data-backup=sqlite
EXPOSE 3456

HEALTHCHECK --start-period=10s --interval=30s --timeout=5s --retries=4 \
  CMD ["/usr/local/bin/droplive-health.sh"]
LABEL io.droplive.readiness.contains.status="\"status\":\"OK\""

USER 1000
ENTRYPOINT ["/usr/local/bin/droplive-entrypoint.sh"]
