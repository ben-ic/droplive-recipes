FROM docker.io/freshrss/freshrss@sha256:bca4407f1f3ecb2e02bd57f704593c64f89bbf3fad53f03ebcf4baecb0122de6

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

COPY --chmod=0555 droplive-start.sh /usr/local/bin/droplive-freshrss-start
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-freshrss-entrypoint
COPY --chmod=0444 droplive-import.php /usr/local/lib/droplive-freshrss-import.php
COPY --chmod=0444 droplive-create-user.php /usr/local/lib/droplive-freshrss-create-user.php

ENV TZ=UTC \
    LISTEN=80 \
    FRESHRSS_INSTALL="--api-enabled --default-user maya --environment production --language en --title Northstar\ Briefing --db-type sqlite --db-base /var/www/FreshRSS/data/freshrss.db"

WORKDIR /var/www/FreshRSS
ENTRYPOINT ["/usr/local/bin/droplive-freshrss-entrypoint"]
CMD ["/usr/local/bin/droplive-freshrss-start"]
EXPOSE 80
