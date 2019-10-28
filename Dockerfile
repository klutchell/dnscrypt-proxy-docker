FROM golang:1.12-alpine3.10 as build

WORKDIR /go/src/github.com/DNSCrypt/dnscrypt-proxy/

ARG DNSCRYPT_PROXY_VERSION=2.0.28
ARG DNSCRYPT_PROXY_URL=https://github.com/DNSCrypt/dnscrypt-proxy/archive/

ENV CGO_ENABLED 0

RUN apk add --no-cache ca-certificates=20190108-r0 curl=7.66.0-r0 \
	&& curl -L "${DNSCRYPT_PROXY_URL}${DNSCRYPT_PROXY_VERSION}.tar.gz" -o /tmp/dnscrypt-proxy.tar.gz \
	&& tar xzf /tmp/dnscrypt-proxy.tar.gz --strip 1 -C /go/src/github.com/DNSCrypt \
	&& go build -v -ldflags="-s -w" \
	&& addgroup -S -g 1001 nonroot \
	&& adduser -S -u 1001 nonroot -G nonroot

WORKDIR /config

RUN cp -a /go/src/github.com/DNSCrypt/dnscrypt-proxy/example-* ./

COPY dnscrypt-proxy.toml ./

# ----------------------------------------------------------------------------

FROM scratch

ARG BUILD_DATE
ARG BUILD_VERSION
ARG VCS_REF

LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.authors="Kyle Harding <https://klutchell.dev>"
LABEL org.opencontainers.image.url="https://klutchell.dev/dnscrypt-proxy"
LABEL org.opencontainers.image.documentation="https://klutchell.dev/dnscrypt-proxy"
LABEL org.opencontainers.image.source="https://klutchell.dev/dnscrypt-proxy"
LABEL org.opencontainers.image.version="${BUILD_VERSION}"
LABEL org.opencontainers.image.revision="${VCS_REF}"
LABEL org.opencontainers.image.title="klutchell/dnscrypt-proxy"
LABEL org.opencontainers.image.description="dnscrypt-proxy is a flexible DNS proxy, with support for encrypted DNS protocols"

COPY --from=build /etc/passwd /etc/passwd
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=build /go/src/github.com/DNSCrypt/dnscrypt-proxy/dnscrypt-proxy /usr/local/bin/
COPY --from=build --chown=1001 /config /config

USER 1001

ENTRYPOINT ["dnscrypt-proxy", "-config", "/config/dnscrypt-proxy.toml"]

RUN ["dnscrypt-proxy", "-version"]
