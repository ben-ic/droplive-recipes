#!/bin/bash
set -eu

if [[ "${1:-}" != "http://127.0.0.1:8080/api/v1/health" ]]; then
  echo 'healthcheck URL must remain the pinned internal Dagu endpoint' >&2
  exit 64
fi

exec 3<>/dev/tcp/127.0.0.1/8080
printf 'GET /api/v1/health HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\n\r\n' >&3
IFS= read -r status_line <&3
case "$status_line" in
  *' 200 '*) ;;
  *) exit 1 ;;
esac

response=$(cat <&3)
case "$response" in
  *'"status":"healthy"'*) exit 0 ;;
  *) exit 1 ;;
esac
