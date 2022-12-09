FROM --platform=$BUILDPLATFORM cgr.dev/chainguard/go:1.19.4 as build

WORKDIR /src

ARG DNSCRYPT_PROXY_VERSION=2.1.2

ADD --chown=nonroot:nonroot https://github.com/DNSCrypt/dnscrypt-proxy/archive/${DNSCRYPT_PROXY_VERSION}.tar.gz /tmp/dnscrypt-proxy.tar.gz

RUN tar xzf /tmp/dnscrypt-proxy.tar.gz --strip 1

WORKDIR /src/dnscrypt-proxy

ARG TARGETOS TARGETARCH

RUN --mount=type=cache,target=/home/nonroot/.cache/go-build,uid=65532,gid=65532 \
    --mount=type=cache,target=/go/pkg \
	CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -v -ldflags="-s -w" -mod vendor

WORKDIR /config

RUN cp -a /src/dnscrypt-proxy/example-* ./

COPY dnscrypt-proxy.toml ./

# ----------------------------------------------------------------------------

# hadolint ignore=DL3007
FROM cgr.dev/chainguard/static:latest

COPY --from=build /src/dnscrypt-proxy/dnscrypt-proxy /usr/local/bin/
COPY --from=build --chown=nobody:nogroup /config /config

# TODO: switch to 'nonroot' user
USER nobody

ENTRYPOINT [ "dnscrypt-proxy" ]

CMD [ "-config", "/config/dnscrypt-proxy.toml" ]
