FROM --platform=$BUILDPLATFORM golang:1.21.6-alpine3.18@sha256:fb1ab21367385fa0f92c3d8c7037a7e2b9b01e14090fd362449bde503d11ea47 as build

WORKDIR /src

# renovate: datasource=github-tags depName=DNSCrypt/dnscrypt-proxy
ARG DNSCRYPT_PROXY_VERSION=2.1.5

ADD https://github.com/DNSCrypt/dnscrypt-proxy/archive/${DNSCRYPT_PROXY_VERSION}.tar.gz /tmp/dnscrypt-proxy.tar.gz

RUN tar xzf /tmp/dnscrypt-proxy.tar.gz --strip 1

WORKDIR /src/dnscrypt-proxy

ARG TARGETOS TARGETARCH TARGETVARIANT

RUN --mount=type=cache,target=/home/nonroot/.cache/go-build,uid=65532,gid=65532 \
    --mount=type=cache,target=/go/pkg \
	CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH GOARM=${TARGETVARIANT#v} go build -v -ldflags="-s -w" -mod vendor

WORKDIR /config

RUN cp -a /src/dnscrypt-proxy/example-* ./

COPY dnscrypt-proxy.toml ./

# ----------------------------------------------------------------------------
FROM --platform=$BUILDPLATFORM golang:1.21.6-alpine3.18@sha256:fb1ab21367385fa0f92c3d8c7037a7e2b9b01e14090fd362449bde503d11ea47 as probe

WORKDIR /src/dnsprobe

ARG TARGETOS TARGETARCH TARGETVARIANT

COPY dnsprobe/ ./

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH GOARM=${TARGETVARIANT#v} go build -o /usr/local/bin/dnsprobe .

# ----------------------------------------------------------------------------
# hadolint ignore=DL3007
FROM cgr.dev/chainguard/static:latest@sha256:bda736ff75ec4b76ecd120d6ccf0b9428419cf4568a5d786a7d77ba23a9f6992

COPY --from=build /src/dnscrypt-proxy/dnscrypt-proxy /usr/local/bin/
COPY --from=probe /usr/local/bin/dnsprobe /usr/local/bin/
COPY --from=build --chown=nobody:nogroup /config /config

USER nobody

ENTRYPOINT [ "dnscrypt-proxy" ]

CMD [ "-config", "/config/dnscrypt-proxy.toml" ]
