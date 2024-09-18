#!/usr/bin/env bash
set -eEuo pipefail

_shutdown() {
  trap '' TERM INT
  echo ""
  echo "_shutdown"

  if [[ -f /tmp/cloudflared_tunnel.pid ]]; then
    cloudflared_tunnel_pid=$(cat /tmp/cloudflared_tunnel.pid)
    kill "$cloudflared_tunnel_pid" || echo "failed to kill cloudflared tunnel"
    wait "$cloudflared_tunnel_pid" || echo "failed to wait cloudflared tunnel"
  fi

  kill 0
  wait

  exit "$1"
}
trap '_shutdown 0' TERM INT

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

case "${STORAGE:-hang}" in
  hang)
    echo "hang"
    tail -f /dev/null & wait
  ;;
  s3)
    # https://github.com/distribution/distribution/issues/2870
    export REGISTRY_STORAGE_S3_REGIONENDPOINT="s3.${AWS_REGION}.amazonaws.com"
  ;;
  gcs)
    if [[ ! -f /keyfile.json ]]
    then
      echo "missing /keyfile.json"
      sleep 3
      exit 1
    fi
    :
  ;;
  *)
    echo "unknown STORAGE: '$STORAGE'"
    sleep 3
    exit 1
  ;;
esac

# otherwise load balanced instances fail (says logs if this is not set)
export REGISTRY_HTTP_SECRET=abbacdabbacdacdc

(
  regctl registry set --tls disabled 127.0.0.1:5000

  if [[ "${REGISTLER_KEEP:--1}" == "-1" ]]; then
    echo "REGISTLER_KEEP not set or set to -1, skipping cleanup"
    tail -f /dev/null & wait
  fi

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
case "${STORAGE:-}" in
  s3)
    envsubst < /app/config.template.s3.yml >> /config.yml
  ;;
  gcs)
    envsubst < /app/config.template.gcs.yml >> /config.yml
  ;;
esac

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

    echo $BASHPID > /tmp/cloudflared_tunnel.pid
    exec cloudflared tunnel --no-autoupdate --metrics 0.0.0.0:9090 \
      run --url "http://127.0.0.1:5000" "$CLOUDFLARED_TUNNEL_ID"
  ) 2>&1 | sed -le "s#^#cloudflared tunnel: #;" &
fi

if [[ "${CADDY_ENABLED:-}" == "yes" ]]
then
  (
    exec caddy reverse-proxy --from="$CADDY_HOSTNAME" --to="127.0.0.1:5000"
  ) 2>&1 | sed -le "s#^#caddy: #;" &
fi

cat /config.yml
registry serve /config.yml &

wait -n
_shutdown 1
