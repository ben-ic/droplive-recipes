FROM docker.io/wisemapping/wisemapping@sha256:fdc5503134fe7e701cd2603b8c61be0f5abe982c53ea9b002352875c5dbc8e1e

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/wisemapping/wisemapping-open-source" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# The pinned upstream image serves its SPA shell at /, but that route asks for
# an account before the router has selected a page and renders a generic request
# error. Its supported /c/login route opens the usable sign-in/sign-up screen.
RUN sed -i '/# Frontend routes/a\  location = / { absolute_redirect off; return 302 /c/login; }' \
      /etc/nginx/http.d/default.conf

EXPOSE 80
