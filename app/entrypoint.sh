#!/usr/bin/env bash
set -eEuo pipefail

_shutdown() {
  trap '' TERM INT

  if [[ -f /tmp/cloudflared_tunnel.pid ]]; then
    cloudflared_tunnel_pid=$(cat /tmp/cloudflared_tunnel.pid)
    kill "$cloudflared_tunnel_pid" || echo "failed to kill cloudflared tunnel"
    wait "$cloudflared_tunnel_pid" || echo "failed to wait cloudflared tunnel"
  fi

  kill 0
  wait

  exit 0
}
trap _shutdown TERM INT

_on_error() {
  trap '' ERR
  line_path=$(caller)
  line=${line_path% *}
  path=${line_path#* }

  echo ""
  echo "ERR $path:$line $BASH_COMMAND exited with $1"
  exit 1
}
trap '_on_error $?' ERR

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

  delay=$((RANDOM % 500 + 60))
  sleep $delay

  while true; do
    ./cleanup.sh
    echo "cleanup exited!"
    sleep 1
  done
) 2>&1 | sed -le "s#^#cleanup: #;" &

envsubst < /app/config.template.yml > /config.yml

if [[ "${CLOUDFLARED_ACCOUNT_TAG:-}" != "" ]]
then
  rm -rf "$HOME/.cloudflared" || true
  mkdir -p "$HOME/.cloudflared"
  envsubst < /app/cloudflared_tunnel.template.json > "$HOME/.cloudflared/${CLOUDFLARED_TUNNEL_ID}.json"

  (
    healthcheck_url="http://127.0.0.1:5000"
    while true; do
      curl -sf "$healthcheck_url" && break
      echo "waiting for $healthcheck_url"
      sleep 1
    done
    echo "registry healthy"

    #exec cloudflared tunnel --no-autoupdate run --url "http://127.0.0.1:5000" "$CLOUDFLARED_TUNNEL_ID"
  ) 2>&1 | sed -le "s#^#cloudflared tunnel: #;" &
  cloudflared_tunnel_pid=$!
  echo "$cloudflared_tunnel_pid" >/tmp/cloudflared_tunnel.pid
fi


cat /config.yml
exec registry serve /config.yml
