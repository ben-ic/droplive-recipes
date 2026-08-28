FROM docker.io/library/python:3.13-slim@sha256:7ce4b6dfe35e55397b7cda544f8a13f191b7ae28dc5aad71fe664dbc9bc2623f

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256

LABEL org.opencontainers.image.revision="54a22d519fd67f3e7628c1ce79df65a6aed0aa14" \
      org.opencontainers.image.source="https://github.com/woofix/visio_display" \
      org.opencontainers.image.version="2.0.4" \
      org.opencontainers.image.licenses="GPL-3.0-only" \
      org.droplive.requested-source.commit="${DROPLIVE_SOURCE_COMMIT}" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    ADMIN_USER=maya \
    MEDIA_DIR=/app/static/data \
    PRIVATE_DIR=/app/data \
    APP_REPOSITORY_URL=https://github.com/woofix/visio_display \
    SESSION_LIFETIME_MINUTES=480 \
    GUNICORN_WORKERS=2 \
    VISIO_DEMO_MODE=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl ffmpeg poppler-utils \
        fonts-dejavu-core fonts-dejavu-extra fonts-liberation2 \
        fonts-noto-core fonts-roboto fonts-open-sans fonts-lato fonts-cantarell \
    && curl -LfsS -o /tmp/visio-display.tar.gz \
        https://github.com/woofix/visio_display/archive/54a22d519fd67f3e7628c1ce79df65a6aed0aa14.tar.gz \
    && echo "bd61563996cd658e10465ca301db3d9d24c3cbcd448f657184722a54718ede3a  /tmp/visio-display.tar.gz" | sha256sum -c - \
    && mkdir -p /app \
    && tar -xzf /tmp/visio-display.tar.gz --strip-components=1 -C /app \
    && rm /tmp/visio-display.tar.gz \
    && python -m pip install --upgrade "pip==24.3.1" \
    && python -m pip install --no-cache-dir -r /app/web/requirements.txt \
    && apt-get purge -y curl \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /root/.cache

WORKDIR /app/web

COPY --chmod=0555 generate_demo_media.py /usr/local/lib/generate-visio-demo-media.py
COPY --chmod=0555 seed_demo.py /usr/local/lib/seed-visio-demo.py
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-visio-display

RUN python /usr/local/lib/generate-visio-demo-media.py /opt/droplive-visio-seed/original \
    && groupadd --gid 1000 visio \
    && useradd --uid 1000 --gid 1000 --home-dir /app --shell /usr/sbin/nologin visio \
    && mkdir -p /app/static/data /app/data \
    && chown -R visio:visio /app /opt/droplive-visio-seed

USER visio
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/droplive-visio-display"]
CMD ["sh", "-c", "exec gunicorn -w \"${GUNICORN_WORKERS:-2}\" -b 0.0.0.0:8080 --timeout 600 --preload wsgi:app"]
