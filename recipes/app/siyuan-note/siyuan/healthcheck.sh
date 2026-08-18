#!/bin/sh
set -eu

wget -q -T 4 -O - http://127.0.0.1:6806/api/system/bootProgress | grep -Eq '"code":[[:space:]]*0'
wget -q -T 4 -O - http://127.0.0.1:6806/api/system/bootProgress | grep -Eq '"progress":[[:space:]]*100'
