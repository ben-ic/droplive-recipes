#!/bin/sh
set -e

# Fusion exits at once without this: "FUSION_PASSWORD is required". It hashes
# the value with bcrypt, which rejects anything over 72 bytes, so hex96 (96
# characters) kills it at boot and hex64 is the only usable choice. Fusion signs
# in with a password and no username, so no username is declared.
# droplive: generate=hex64 ownership=app purpose=owner-bootstrap lifecycle=stable rotation=none name=FUSION_PASSWORD capability=owner-login
: "${FUSION_PASSWORD:?DropLive must generate the initial owner password}"

exec ./fusion
