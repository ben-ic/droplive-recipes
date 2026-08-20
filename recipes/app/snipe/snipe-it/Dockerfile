FROM docker.io/snipe/snipe-it@sha256:18cc45da877ec5509e1fdb17b492db42e37d3ca3bc89d885d82e9c0ecdae1253

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/snipe/snipe-it" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# Laravel reads these from its own .env contract. The connection driver and the
# demo-appropriate app mode are public defaults, so they belong here; the host,
# port, database, username and password come from the companion, and APP_URL is
# the session origin.
ENV APP_ENV=production \
    APP_DEBUG=false \
    DB_CONNECTION=mysql

# supervisord's config sets neither logfile nor pidfile, so both default to
# $CWD/... -- and $CWD is /var/www/html, the application directory. On a
# read-only root it dies before it starts apache:
#
#   OSError: [Errno 30] Read-only file system: '/var/www/html/supervisord.log'
#
# Send the log to stdout, which is where a demo wants it anyway, and put the
# pidfile and child logs on paths that are writable at runtime.
RUN sed -i 's|^\[supervisord\]|[supervisord]\nlogfile=/dev/stdout\nlogfile_maxbytes=0\npidfile=/run/supervisord.pid\nchildlogdir=/tmp|' /supervisord.conf

# The image ships an SSL vhost pointing at a certificate under /var/lib/snipeit,
# which a demo's managed path arrives without:
#
#   SSLCertificateFile: file '/var/lib/snipeit/ssl/snipeit-ssl.crt' does not
#   exist or is empty
#
# apache refuses the whole config over it and supervisord restarts it forever.
# A demo is reached over the platform's own HTTPS and serves plain HTTP here, so
# the vhost has nothing to do; disabling it is simpler than minting a
# certificate nothing presents.
RUN a2dissite 001-default-ssl && a2dismod ssl

# apache opens its log files before it serves anything, and a read-only root
# refuses:
#
#   (30)Read-only file system: AH00091: apache2: could not open error log file
#   /var/log/apache2/error.log
#   AH00015: Unable to open logs
#
# Point them at the container's own streams. A demo wants its request log where
# the receipt can see it anyway, and this needs no writable path.
RUN ln -sf /dev/stderr /var/log/apache2/error.log \
 && ln -sf /dev/stdout /var/log/apache2/access.log \
 && ln -sf /dev/stdout /var/log/apache2/other_vhosts_access.log

# startup.sh copies Passport's migrations into the application's own migrations
# directory on every boot, and a read-only root refuses:
#
#   cp: cannot create regular file
#   '/var/www/html/database/migrations/..._create_oauth_clients_table.php':
#   Read-only file system
#
# Nothing fails loudly -- the app serves -- but the OAuth tables are then never
# created and API tokens do not work. The copy has no runtime input, so doing it
# here makes the files present and the boot-time step a no-op.
RUN cp -a /var/www/html/vendor/laravel/passport/database/migrations/. \
          /var/www/html/database/migrations/

# Keep the shipped storage tree aside so the entrypoint can restore it into the
# managed path, which arrives empty. See droplive-entrypoint.sh.
RUN cp -a /var/www/html/storage /opt/droplive-storage-template

COPY --chmod=0755 droplive-entrypoint.sh /usr/local/bin/droplive-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/droplive-entrypoint.sh"]

EXPOSE 80
