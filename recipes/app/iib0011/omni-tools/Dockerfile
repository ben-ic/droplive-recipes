# syntax=docker/dockerfile:1
# OmniTools v0.6.0, official linux/amd64 image manifest.
ARG SOURCE_DATE_EPOCH=1759503307
FROM docker.io/iib0011/omni-tools@sha256:a48e5ce65be2fda513e9646ebfe428c3bd5bb3659bc4b87bf74d0fc9a74587b7

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# DropLive's current runtime does not advertise low-port binding, so nginx's only
# listener moves to 8080. This happens at BUILD time: the run plane mounts the
# root filesystem read-only, so the previous startup `sed -i` was a write that
# could never succeed there. Doing it here is also deterministic — the artifact
# ships already listening on 8080 rather than rewriting itself on every boot —
# and it lets the official entrypoint and command stand unmodified, which is what
# the recipe wanted in the first place.
RUN sed -i 's/listen       80;/listen       8080;/' /etc/nginx/conf.d/default.conf \
    && grep -q 'listen       8080;' /etc/nginx/conf.d/default.conf

# The official nginx entrypoint creates its request cache at startup. Point it
# below the existing ephemeral /tmp boundary, the same shape BentoPDF and
# CyberChef use, instead of adding persistent data.
RUN rm -rf /var/cache/nginx /etc/nginx/tmp \
    && ln -s /tmp /var/cache/nginx \
    && ln -s /tmp /etc/nginx/tmp

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]

EXPOSE 8080
