FROM ghcr.io/0x2e/fusion@sha256:4fa7eead46976f2090cfbb7e60f29946eccf0a5979c1fc168d7a9d89648a6a9b

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256

# The image runs ./fusion relative to its workdir, and DropLive reads
# declarations only from an absolute entrypoint path a recipe COPY maps back.
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD []

EXPOSE 8080
