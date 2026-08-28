FROM ghcr.io/traceapps/lifttrace@sha256:5af7ae8e64823bf7d46c54d7913886bf58a6ab98fe73b942e2af1650267d058f

ENV DB_PATH=/data/db/lifttrace.db \
    UPLOADS_PATH=/data/uploads \
    EXERCISE_SOURCES=""

COPY --chmod=0444 seed-lifttrace.mjs /usr/local/lib/droplive-lifttrace-seed.mjs
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-lifttrace

ENTRYPOINT ["/usr/local/bin/droplive-lifttrace"]
CMD ["node", "index.js"]

EXPOSE 3003
