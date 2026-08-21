FROM ghcr.io/0x2e/fusion@sha256:4fa7eead46976f2090cfbb7e60f29946eccf0a5979c1fc168d7a9d89648a6a9b

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256

# Fusion exits at once unless FUSION_PASSWORD is set, and it signs in with a
# password only -- it has no username. A minted credential cannot be shown on
# the sign-in card, because that card needs a username literal. The demo gives
# each visitor their own private instance for one short session, so the sign-in
# wall guards nothing here and only hides the reader behind a password nobody
# was told. This is the switch Fusion itself provides for that case.
ENV FUSION_ALLOW_EMPTY_PASSWORD=true

EXPOSE 8080
