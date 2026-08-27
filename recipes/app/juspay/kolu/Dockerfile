FROM docker.io/nixos/nix@sha256:7e50d5c88f7aa800768c9e7016bf32b3229805fbc74f31487eea5c0547a32434

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256

ENV NIX_CONFIG="experimental-features = nix-command flakes"

LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/juspay/kolu" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

RUN mkdir -p /opt \
    && nix profile install --accept-flake-config --profile /opt/kolu \
      "github:juspay/kolu/${DROPLIVE_SOURCE_COMMIT}#default" \
    && nix profile install --profile /opt/runtime \
      "github:NixOS/nixpkgs/d8e1b5b3c6faedb60c060c5dec2cc17c0c2473a0#bashInteractive" \
      "github:NixOS/nixpkgs/d8e1b5b3c6faedb60c060c5dec2cc17c0c2473a0#coreutils" \
      "github:NixOS/nixpkgs/d8e1b5b3c6faedb60c060c5dec2cc17c0c2473a0#curl" \
      "github:NixOS/nixpkgs/d8e1b5b3c6faedb60c060c5dec2cc17c0c2473a0#findutils" \
      "github:NixOS/nixpkgs/d8e1b5b3c6faedb60c060c5dec2cc17c0c2473a0#gawk" \
      "github:NixOS/nixpkgs/d8e1b5b3c6faedb60c060c5dec2cc17c0c2473a0#git" \
      "github:NixOS/nixpkgs/d8e1b5b3c6faedb60c060c5dec2cc17c0c2473a0#gnugrep" \
      "github:NixOS/nixpkgs/d8e1b5b3c6faedb60c060c5dec2cc17c0c2473a0#gnused" \
    && rm -f /etc/passwd /etc/group \
    && printf 'root:x:0:0:root:/root:/bin/sh\ndemo:x:1000:1000:Demo:/home/demo:/opt/runtime/bin/bash\n' > /etc/passwd \
    && printf 'root:x:0:\ndemo:x:1000:\n' > /etc/group \
    && mkdir -p /workspace /run/kolu /run/padi /opt/droplive/bin /home/demo \
    && chown -R 1000:1000 /workspace /run/kolu /run/padi /home/demo

COPY --chmod=0755 droplive-entrypoint.sh world-workspace.sh world-arrivals.sh /opt/droplive/bin/

ENV HOME=/home/demo \
    PATH=/opt/droplive/bin:/opt/kolu/bin:/opt/runtime/bin \
    KOLU_STATE_DIR=/run/kolu \
    KOLU_PADI_STATE_DIR=/run/padi \
    SHELL=/opt/runtime/bin/bash \
    TERM=xterm-256color

USER 1000:1000
WORKDIR /workspace/northstar-relay
EXPOSE 7681
ENTRYPOINT ["/opt/droplive/bin/droplive-entrypoint.sh"]
