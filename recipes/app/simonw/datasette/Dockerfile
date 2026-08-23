FROM docker.io/datasetteproject/datasette@sha256:0f57db16cf4eb6cca57f1cedaa0a696bca1c65a1d75b8f7ee372c2dd909a32a0

ARG DROPLIVE_SOURCE_COMMIT
ARG DROPLIVE_SOURCE_TREE_SHA256
ARG DROPLIVE_RUNTIME_CONTRACT_SHA256
LABEL org.opencontainers.image.revision="${DROPLIVE_SOURCE_COMMIT}" \
      org.opencontainers.image.source="https://github.com/simonw/datasette" \
      org.droplive.source.tree.sha256="${DROPLIVE_SOURCE_TREE_SHA256}" \
      org.droplive.runtime.contract.sha256="${DROPLIVE_RUNTIME_CONTRACT_SHA256}"

# Datasette explores a database it is given. This one is the Northstar Relay
# company, built here from one SQL script rather than shipped as a binary blob,
# so what the demo serves is reviewable in the recipe. SQLite is in the image's
# own Python, so nothing is installed to do it.
COPY seed/northstar.sql /tmp/northstar.sql
COPY --chmod=0444 seed/metadata.json /usr/local/lib/droplive-datasette-metadata.json
RUN python3 -c "import sqlite3; db = sqlite3.connect('/usr/local/lib/northstar.db'); db.executescript(open('/tmp/northstar.sql').read()); db.commit(); db.close()" \
    && rm -f /tmp/northstar.sql \
    && chmod 0444 /usr/local/lib/northstar.db

EXPOSE 8001

# The image's own command binds Uvicorn to 127.0.0.1, so nothing outside the
# container can reach it: "Uvicorn running on http://127.0.0.1:8001". Serve on
# all interfaces instead, and open the demo on the company rather than on an
# empty instance the visitor has to find data for.
#
# --immutable is the honest declaration: the file is read-only, and it lets
# Datasette cache row counts instead of recounting half a million rows a page.
CMD ["datasette", "serve", "--host", "0.0.0.0", "--port", "8001", \
     "--metadata", "/usr/local/lib/droplive-datasette-metadata.json", \
     "--immutable", "/usr/local/lib/northstar.db"]
