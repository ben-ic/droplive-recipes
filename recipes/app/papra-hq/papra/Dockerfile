# syntax=docker/dockerfile:1
# Papra 26.6.1, official rootless linux/amd64 image manifest.
ARG SOURCE_DATE_EPOCH=1783195851
FROM ghcr.io/papra-hq/papra@sha256:a7fedb3d052b734c932b7879844c72f1d6569ede44e3a675f1dc61e45e38c059
ARG SOURCE_DATE_EPOCH
ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256

LABEL org.droplive.source.commit="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}" \
      org.droplive.runtime.contract="papra-26.6.1"

# Preserve the official non-root runtime. DropLive presents an empty managed
# filesystem, so the wrapper creates Papra's documented durable subdirectories
# idempotently before handing control back to the official Node entrypoint.
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-papra-entrypoint.sh

# Keep password-reset links disabled until the owner explicitly configures a
# real mail driver. The first registered user is the deterministic administrator.
ENV AUTH_FIRST_USER_AS_ADMIN=true \
    AUTH_IS_PASSWORD_RESET_ENABLED=false \
    AUTH_IS_EMAIL_VERIFICATION_REQUIRED=false \
    EMAILS_DRIVER=logger \
    PROCESS_MODE=all

VOLUME ["/app/app-data"]

# Stated explicitly so the managed-data adapter is a declared contract rather than
# an inference. The sqlite adapter archives every file under the data dirs and
# additionally requires a readable database, so it is the stronger of the two.
LABEL io.droplive.data-backup=sqlite

EXPOSE 1221

# /api/health executes a database SELECT and reports both component and aggregate
# health; /api/ping only proves that the HTTP process is answering.
HEALTHCHECK --start-period=30s --interval=30s --timeout=5s --retries=4 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:1221/api/health').then(async(r)=>{const b=await r.json();if(!r.ok||b.status!=='ok'||b.isDatabaseHealthy!==true||b.isEverythingOk!==true)process.exit(1)}).catch(()=>process.exit(1))"]

# Preserve the three exact response semantics in DropLive's external readiness
# contract; an HTTP 200 without all three is not healthy enough for traffic.
LABEL io.droplive.readiness.contains.status="\"status\":\"ok\""
LABEL io.droplive.readiness.contains.database="\"isDatabaseHealthy\":true"
LABEL io.droplive.readiness.contains.everything="\"isEverythingOk\":true"

ENTRYPOINT ["/usr/local/bin/droplive-papra-entrypoint.sh"]
CMD ["pnpm", "start:with-migrations"]
