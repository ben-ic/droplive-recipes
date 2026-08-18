#!/bin/sh
set -eu

wget -qO- http://127.0.0.1:8080/readiness
