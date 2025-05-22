#!/usr/bin/env bash

set -eEuo pipefail

case "${REGISTRY_AUTH:-}" in
  htpasswd)
    exec curl -sfL -o /dev/null "${REGISTLER_USERNAME}:${REGISTLER_PASSWORD}@127.0.0.1:5000/v2"
  ;;
  *)
    exec curl -sfL "127.0.0.1:5000/v2"
  ;;
esac
