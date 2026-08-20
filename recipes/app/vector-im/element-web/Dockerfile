FROM docker.io/vectorim/element-web@sha256:a9be04cef41ed94cba0dcaeca5a81f89826d4f8be3d57ba5a6fa988f34eda703

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/vector-im/element-web" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

EXPOSE 80

# Render the nginx config at build time and remove the template.
#
# The image's entrypoint renders /etc/nginx/templates/default.conf.template into
# /etc/nginx/conf.d on every start, which a read-only root refuses:
#
#   20-envsubst-on-templates.sh: ERROR: /etc/nginx/templates exists,
#     but /etc/nginx/conf.d is not writable
#
# nginx then starts with no server block at all -- listening on nothing, while
# the container still reports itself running.
#
# ELEMENT_WEB_PORT is fixed for a demo, so the render has nothing to decide at
# runtime. Doing it here needs no writable path and no volume, and with the
# template gone the entrypoint step skips itself.
USER root
RUN envsubst '${ELEMENT_WEB_PORT}' \
      < /etc/nginx/templates/default.conf.template \
      > /etc/nginx/conf.d/default.conf \
 && rm -rf /etc/nginx/templates
USER nginx
