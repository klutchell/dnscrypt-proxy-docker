FROM --platform=$BUILDPLATFORM golang:1.21.6-alpine3.18@sha256:5a2821c9183d5e69a0d588c5c1f66b4b68d37f3a14c260d99a620adcfda37f33 as build

WORKDIR /src

# renovate: datasource=github-tags depName=DNSCrypt/dnscrypt-proxy
ARG DNSCRYPT_PROXY_VERSION=2.1.5

ADD https://github.com/DNSCrypt/dnscrypt-proxy/archive/${DNSCRYPT_PROXY_VERSION}.tar.gz /tmp/dnscrypt-proxy.tar.gz

RUN tar xzf /tmp/dnscrypt-proxy.tar.gz --strip 1

WORKDIR /src/dnscrypt-proxy

ARG TARGETOS TARGETARCH

ARG CGO_ENABLED=0 \
    GOOS=$TARGETOS \
    GOARCH=$TARGETARCH \
    GOARM=$TARGETVARIANT

RUN --mount=type=cache,target=/home/nonroot/.cache/go-build,uid=65532,gid=65532 \
    --mount=type=cache,target=/go/pkg \
	go build -v -ldflags="-s -w" -mod vendor

WORKDIR /config

RUN cp -a /src/dnscrypt-proxy/example-* ./

COPY dnscrypt-proxy.toml ./

# ----------------------------------------------------------------------------
FROM --platform=$BUILDPLATFORM golang:1.21.6-alpine3.18@sha256:5a2821c9183d5e69a0d588c5c1f66b4b68d37f3a14c260d99a620adcfda37f33 as probe

WORKDIR /src/dnsprobe

ARG TARGETOS TARGETARCH

ARG CGO_ENABLED=0 \
    GOOS=$TARGETOS \
    GOARCH=$TARGETARCH \
    GOARM=$TARGETVARIANT

COPY dnsprobe/ ./

RUN go build -o /usr/local/bin/dnsprobe .

# ----------------------------------------------------------------------------
# hadolint ignore=DL3007
FROM cgr.dev/chainguard/static:latest@sha256:177d0e55109c4565c5ab6fdbea232fe7fc3670b011d7dd4027f9e8a1d72f0b65

COPY --from=build /src/dnscrypt-proxy/dnscrypt-proxy /usr/local/bin/
COPY --from=probe /usr/local/bin/dnsprobe /usr/local/bin/
COPY --from=build --chown=nobody:nogroup /config /config

USER nobody

ENTRYPOINT [ "dnscrypt-proxy" ]

CMD [ "-config", "/config/dnscrypt-proxy.toml" ]
