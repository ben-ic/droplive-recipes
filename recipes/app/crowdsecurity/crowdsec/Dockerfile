FROM docker.io/crowdsecurity/crowdsec@sha256:fdb487e130095709c1b1c5ba2bd2b461e6715676076e5f774230dcf47d366f76

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# A demo does not enrol with the vendor.
#
# `build/docker/docker_start.sh` runs `cscli capi register` against
# https://api.crowdsec.net/ during startup unless this is set, and the container
# exits when that call fails:
#
#   Error: api client register ('https://api.crowdsec.net/'):
#     Post "https://api.crowdsec.net/v3/watchers": dial tcp: lookup ...
#
# Central API enrolment links an installation to a CrowdSec account and shares
# signals with it. That is an account feature, not the thing being demonstrated,
# and a fifteen-minute disposable µVM has no account to link. Local API,
# parsers, scenarios and the console all run without it.
ENV DISABLE_ONLINE_API=true

# Create the data directory the image's own startup script links into but never
# creates. See droplive-entrypoint.sh for why it is absent on a demo and present
# everywhere else. The image's own entrypoint still runs; this only precedes it.
COPY --chmod=0755 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/droplive-entrypoint.sh"]

EXPOSE 8080
