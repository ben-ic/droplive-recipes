# syntax=docker/dockerfile:1
# drawDB v1.8.1, official linux/amd64 image manifest.
ARG SOURCE_DATE_EPOCH=1783064186
FROM ghcr.io/drawdb-io/drawdb@sha256:052410e6b6bcd5bddf0462b41f94e0fb91039e2e7d8e75e38f0b1b7fbcdd3307

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# The current DropLive runtime does not advertise low-port binding, so nginx's
# listener moves to 8080 at BUILD time. It used to happen in CMD, which is a
# write to a root filesystem the run plane mounts read-only: a clean build
# followed by a container that cannot start. The grep makes a pattern that stops
# matching upstream fail the build rather than the boot.
RUN sed -i 's/listen 80;/listen 8080;/' /etc/nginx/conf.d/default.conf \
    && grep -q 'listen 8080;' /etc/nginx/conf.d/default.conf

# The official nginx entrypoint creates its request cache at startup. Point it
# below the existing ephemeral /tmp boundary, as BentoPDF and CyberChef do.
RUN rm -rf /var/cache/nginx /etc/nginx/tmp \
    && ln -s /tmp /var/cache/nginx \
    && ln -s /tmp /etc/nginx/tmp

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]

EXPOSE 8080
