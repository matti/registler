FROM registry:2.8.1

# gettext: envsubst
# libcap: setcap
RUN apk add --no-cache \
  bash gettext \
  curl jq \
  libcap

COPY --from=mattipaksula/harderdns:sha-674b3ac /* /usr/local/bin
RUN setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/harderdns

RUN [ "$(uname -m)" = "aarch64" ] && arch=arm64 || arch=amd64 \
  && cd /usr/local \
  && curl -Lsf -o /usr/local/bin/regctl https://github.com/regclient/regclient/releases/download/v0.4.5/regctl-linux-${arch} \
  && chmod +x /usr/local/bin/regctl

WORKDIR /app
COPY app .

ENTRYPOINT [ "/app/entrypoint.sh" ]
