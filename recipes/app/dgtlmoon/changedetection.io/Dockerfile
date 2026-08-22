FROM docker.io/dgtlmoon/changedetection.io@sha256:42e81c2aa97593c52c9a085df9100c38606a0f1387bd30cd9907df0be640d266

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-changedetection
COPY --chmod=0444 droplive-seed.py /usr/local/lib/droplive-changedetection-seed.py
COPY --chmod=0444 droplive-datastore.json /usr/local/share/droplive-changedetection-datastore.json

ENTRYPOINT ["/usr/local/bin/droplive-changedetection"]
CMD ["python", "./changedetection.py", "-d", "/datastore"]
EXPOSE 5000
