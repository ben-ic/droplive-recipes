FROM docker.io/minio/minio@sha256:640c22768ed5dbc92eacc14502a1b06a1c708fa60431345c78dfc22917062e93

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# MinIO refuses a half-configured root account -- the user and the password have
# to arrive together. The username is not a secret and never varies, so it is a
# literal here while the password is generated per demo; see droplive.yaml.
# Without both, MinIO falls back to a credential it announces in its own log:
# "Detected default credentials 'minioadmin:minioadmin', we recommend that you
# change these values".
ENV MINIO_ROOT_USER=minioadmin

EXPOSE 9001

# The image has no default command: started bare it prints its usage banner and
# exits, which is exactly what the build reported. Serve /data, and put the
# console on the port the recipe declares.
CMD ["server", "/data", "--console-address", ":9001"]

