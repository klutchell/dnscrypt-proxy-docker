FROM --platform=$BUILDPLATFORM golang:1.19.2-alpine as build

WORKDIR /src

ARG DNSCRYPT_PROXY_VERSION=2.1.2

# hadolint ignore=DL3018
RUN apk add --no-cache ca-certificates curl \
	&& curl -fsSL "https://github.com/DNSCrypt/dnscrypt-proxy/archive/${DNSCRYPT_PROXY_VERSION}.tar.gz" -o /tmp/dnscrypt-proxy.tar.gz \
	&& tar xzf /tmp/dnscrypt-proxy.tar.gz --strip 1 \
	&& go mod vendor

WORKDIR /src/dnscrypt-proxy

ENV CGO_ENABLED 0

ARG TARGETOS TARGETARCH

RUN GOOS=$TARGETOS GOARCH=$TARGETARCH go build -v -ldflags="-s -w" -mod vendor

WORKDIR /config

RUN cp -a /src/dnscrypt-proxy/example-* ./

COPY dnscrypt-proxy.toml ./

# ----------------------------------------------------------------------------

FROM scratch

COPY --from=build /etc/passwd /etc/group /etc/
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=build /src/dnscrypt-proxy/dnscrypt-proxy /usr/local/bin/
COPY --from=build --chown=nobody:nogroup /config /config

USER nobody

ENTRYPOINT [ "dnscrypt-proxy" ]

CMD [ "-config", "/config/dnscrypt-proxy.toml" ]
