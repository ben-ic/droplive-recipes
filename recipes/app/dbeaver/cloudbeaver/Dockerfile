FROM docker.io/dbeaver/cloudbeaver@sha256:bb4968967796856e3b89e3ece33654d69aaed52113b6bf9d2d2d0056956a4722

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/dbeaver/cloudbeaver" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

ENV CB_SERVER_NAME="DropLive Database Demo" \
    CB_ADMIN_NAME="droplive-admin" \
    CLOUDBEAVER_APP_ANONYMOUS_ACCESS_ENABLED=false \
    CLOUDBEAVER_POLICY_REQUIRE_MIXED_CASE=false \
    CLOUDBEAVER_POLICY_MIN_NUMBER_COUNT=0

COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-cloudbeaver-entrypoint

EXPOSE 8978

ENTRYPOINT ["/usr/local/bin/droplive-cloudbeaver-entrypoint"]
CMD ["./launch-product.sh"]
