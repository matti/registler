FROM registry:2.8.1

# gettext: envsubst
# libcap: setcap
RUN apk add --no-cache \
  bash gettext \
  libcap

COPY --from=mattipaksula/harderdns:sha-674b3ac /* /usr/local/bin
RUN setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/harderdns

WORKDIR /app
COPY app .

ENTRYPOINT [ "/app/entrypoint.sh" ]
