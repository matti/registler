#!/usr/bin/env bash
set -euo pipefail

# https://github.com/distribution/distribution/issues/2870
export REGISTRY_STORAGE_S3_REGIONENDPOINT="s3.${REGION}.amazonaws.com"

# otherwise load balanced instances fail (says logs if this is not set)
export REGISTRY_HTTP_SECRET=abbacdabbacdacdc

envsubst < /app/config.template.yml > /config.yml

cat /config.yml
exec registry serve /config.yml