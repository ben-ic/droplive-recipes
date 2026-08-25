#!/bin/sh
set -eu

# DEFAULT_LLMS is the application's own required form: an ordered provider:model
# chain. Its model half is not a value DropLive can name -- it is one DropLive
# supplies and this line composes. A plan binding names a SOURCE, so Compose asking
# for "openai-compatible:${OPENAI_COMPATIBLE_MODEL}" asks the platform to express a
# template it has no way to represent, and the recipe was refused for it.
#
# Deriving it here keeps the modern form the application prefers while leaving the
# platform to bind only what it can name. `:?` so a missing binding still fails
# loudly rather than composing a chain with an empty model.
: "${OPENAI_COMPATIBLE_MODEL:?DropLive must supply the emulated model name}"
export DEFAULT_LLMS="${DEFAULT_LLMS:-openai-compatible:${OPENAI_COMPATIBLE_MODEL}}"

exec docker-entrypoint.sh "$@"
