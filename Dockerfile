FROM registry:2.8.1

# gettext: envsubst
# libcap: setcap
RUN apk add --no-cache \
  bash gettext \
  curl jq \
  libcap sed \
  aws-cli \
  apache2-utils

COPY --from=mattipaksula/harderdns:sha-674b3ac /* /usr/local/bin
RUN setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/harderdns

RUN [ "$(uname -m)" = "aarch64" ] && arch=arm64 || arch=amd64 \
  && cd /usr/local \
  && curl -Lsf -o /usr/local/bin/regctl "https://github.com/regclient/regclient/releases/download/v0.4.5/regctl-linux-${arch}" \
  && chmod +x /usr/local/bin/regctl

RUN mkdir /ghjk && cd /ghjk \
  && [ "$(uname -m)" = "aarch64" ] && arch="arm64" || arch="amd64" \
  && curl -Lfso "cloudflared" "https://github.com/cloudflare/cloudflared/releases/download/2025.1.1/cloudflared-linux-${arch}" \
  && chmod +x cloudflared \
  && mv cloudflared /usr/local/bin \
  && rm -rf /ghjk

RUN set -eux ; \
  mkdir /ghjk ; cd /ghjk ; \
  [ "$(uname -m)" = "aarch64" ] && arch="arm64" || arch="amd64" ; \
  curl -Lsfo caddy.tar.gz "https://github.com/caddyserver/caddy/releases/download/v2.8.4/caddy_2.8.4_linux_${arch}.tar.gz" ; \
  tar -xzf caddy.tar.gz ; \
  mv caddy /usr/local/bin

WORKDIR /app
COPY app .

ENTRYPOINT [ "/app/entrypoint.sh" ]
