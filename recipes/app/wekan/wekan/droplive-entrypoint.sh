#!/bin/sh
set -eu

# Declare what Wekan cannot start without, then hand over to the image's own
# entrypoint unchanged.
#
# Wekan reads both from the environment and exits before listening if either is
# missing -- "Error: Must pass options.rootUrl or set ROOT_URL in the server
# environment" -- but its image ships no Compose file and no .env example, so
# nothing in the repository states them. The guards below are the declaration
# surface: DropLive collects each guarded variable and treats it as required.
#
# ROOT_URL is deliberately NOT declared in droplive.yaml. It is an origin-shaped
# name, so the platform supplies the session's own origin once it knows the
# application needs it; declaring it `owner: droplive` would mint a random value
# instead and the app would render links to nowhere.
: "${ROOT_URL:?DropLive supplies the public origin}"
: "${MONGO_URL:?DropLive supplies the mongodb companion}"

exec "$@"
