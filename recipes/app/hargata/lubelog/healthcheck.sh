#!/bin/bash
set -eu

url=${1:?health URL required}
if [[ "${url}" != "http://127.0.0.1:8080/health" ]]; then
  echo "unexpected LubeLogger health URL" >&2
  exit 1
fi

exec 3<>/dev/tcp/127.0.0.1/8080
printf 'GET /health HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\n\r\n' >&3
IFS= read -r status <&3
case "${status}" in
  'HTTP/1.1 200 '*) exit 0 ;;
  *) exit 1 ;;
esac
