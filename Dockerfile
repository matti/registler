FROM --platform=amd64 registry:2.8.1

# gettext: envsubst
# libcap: setcap
RUN apk add --no-cache \
  bash gettext \
  libcap

COPY app .
COPY --from=mattipaksula/harderdns:sha-674b3ac /* /usr/local/bin
RUN setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/harderdns

ENTRYPOINT [ "/app/entrypoint.sh" ]