FROM busybox@sha256:29989570aeecad61a019f684218ea74d4b8c1c74f9e0abeb34ca926b81174ee1 AS busybox

FROM ghcr.io/go-shiori/shiori@sha256:b7eb94ee5ccf24716b4d502961aa9d8b9e9f6d2014cb6553739c25f6d3f29116

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --from=busybox /bin/busybox /bin/busybox
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-shiori-entrypoint

ENTRYPOINT ["/usr/local/bin/droplive-shiori-entrypoint"]
CMD ["server"]
EXPOSE 8080
