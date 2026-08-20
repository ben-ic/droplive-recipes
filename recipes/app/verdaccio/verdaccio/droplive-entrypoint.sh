#!/bin/sh
set -eu

# Verdaccio writes its own address into the page it serves:
#
#   <base href="http://10.64.3.211:4873/">
#   <script src="https://10.64.3.211:4873/-/static/runtime.js">
#
# That is the µVM's bridge address. A visitor's browser cannot reach it, so every
# asset failed and the demo rendered a blank white page while answering 200 at
# the root -- healthy to every probe, useless to a person.
#
# VERDACCIO_PUBLIC_URL is what makes it emit the address the visitor actually
# used. It is optional upstream, which is why nothing bound it: DropLive supplies
# the values an application REQUIRES, and this one only asked politely. Requiring
# it here is what makes the platform fill it in.
: "${VERDACCIO_PUBLIC_URL:?DropLive must supply the public origin}"

exec uid_entrypoint "$@"
