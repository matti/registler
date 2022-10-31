#!/usr/bin/env bash
set -euo pipefail

(
  exec harderdns -retry -tries 3 -stats 60 8.8.8.8:53 9.9.9.9:53 1.1.1.1:53
) >/dev/null 2>&1 &

harderdns test amazonaws.com

# https://github.com/distribution/distribution/issues/2870
export REGISTRY_STORAGE_S3_REGIONENDPOINT="s3.${REGION}.amazonaws.com"

# otherwise load balanced instances fail (says logs if this is not set)
export REGISTRY_HTTP_SECRET=abbacdabbacdacdc

(
  regctl registry set --tls disabled 127.0.0.1:5000

  while true; do
    nc -z 127.0.0.1 5000 && break
    echo "waiting for 127.0.0.1:5000"
    sleep 1
  done

  sleep 60

  while true; do
    ./cleanup.sh
    echo "cleanup exited!"
    sleep 1
  done
) &

envsubst < /app/config.template.yml > /config.yml

cat /config.yml
exec registry serve /config.yml
