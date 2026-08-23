FROM docker.io/kimai/kimai2@sha256:6dfc631996544bb2b7a0a876f5565047c6dc0c2632fa06fe6f3c6c8d0f7350a6 AS upstream

# The image declares /opt/kimai/var as an OCI volume. That is where Symfony keeps
# the cache it warms at startup and the sessions it writes after. DropLive gives a
# demo one private writable rootfs and does not apply Docker's named-volume
# copy-up, so the path arrived as an empty mount, the warmed cache was gone, and
# Kimai answered HTTP 500 to every request including its own health check.
#
# The directory is made BEFORE the declaration is dropped: a VOLUME path exists
# only as a mountpoint the runtime creates, so a plain copy of the filesystem
# would not contain it at all.
FROM upstream AS prepared
RUN mkdir -p /opt/kimai/var && chown -R www-data:www-data /opt/kimai/var

# Copying into a clean stage drops the declaration, so the directory is an
# ordinary part of the session's rootfs. Everything below re-states what that
# stage discards.
FROM scratch
COPY --from=prepared / /

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/kimai/kimai" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# The address of the account the image bootstraps. It is a literal the visitor
# reads off the sign-in card, so the recipe owns it; only the password is minted.
ENV ADMINMAIL=maya@northstar-relay.invalid

# The Northstar company, one complete request per line: the people, the four
# accounts, their projects and activities, and four weeks of timesheets.
COPY --chmod=0444 seed/kimai.requests /usr/local/lib/droplive-kimai-seed.requests
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-kimai

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    PHP_INI_DIR=/usr/local/etc/php \
    APACHE_CONFDIR=/etc/apache2 \
    APACHE_ENVVARS=/etc/apache2/envvars \
    LANG=C.UTF-8 \
    TIMEZONE=Europe/Berlin \
    KIMAI=2.65.0 \
    DATABASE_URL="" \
    TRUSTED_PROXIES=nginx,localhost,127.0.0.1 \
    MAILER_FROM=kimai@example.com \
    MAILER_URL=null://localhost \
    ADMINPASS="" \
    USER_ID="" \
    GROUP_ID="" \
    COMPOSER_MEMORY_LIMIT=-1 \
    COMPOSER_ALLOW_SUPERUSER=1 \
    APP_ENV=prod \
    memory_limit=512M
WORKDIR /var/www/html

EXPOSE 8001

# The upstream pair becomes the command, so the seeder wraps the real startup
# rather than replacing it.
ENTRYPOINT ["/usr/local/bin/droplive-kimai"]
CMD ["docker-php-entrypoint", "/entrypoint.sh"]
