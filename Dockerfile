FROM --platform=amd64 registry:2.8.1

# gettext: envsubst
RUN apk add --no-cache \
  bash gettext

COPY app .

ENTRYPOINT [ "/app/entrypoint.sh" ]