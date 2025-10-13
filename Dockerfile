FROM --platform=$BUILDPLATFORM golang:1.25.2-alpine3.21@sha256:0ae17b3ad9583fcc9c2b195d12f2aa5dd1c18380d3827bd1a81c6e52aded353c AS build

WORKDIR /src

# renovate: datasource=github-tags depName=DNSCrypt/dnscrypt-proxy
ARG DNSCRYPT_PROXY_VERSION=2.1.14

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

ARG NONROOT_UID=65532
ARG NONROOT_GID=65532

RUN addgroup -S -g ${NONROOT_GID} nonroot \
	&& adduser -S -g nonroot -h /home/nonroot -u ${NONROOT_UID} -D -G nonroot nonroot

# ----------------------------------------------------------------------------
FROM scratch AS conf-example

# docker build . --target conf-example --output .
COPY --from=build /config/example-dnscrypt-proxy.toml /dnscrypt-proxy.toml.example

# ----------------------------------------------------------------------------
FROM --platform=$BUILDPLATFORM golang:1.25.2-alpine3.21@sha256:0ae17b3ad9583fcc9c2b195d12f2aa5dd1c18380d3827bd1a81c6e52aded353c AS probe

WORKDIR /src/dnsprobe

ARG TARGETOS TARGETARCH TARGETVARIANT

COPY dnsprobe/ ./

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH GOARM=${TARGETVARIANT#v} go build -o /usr/local/bin/dnsprobe .

# ----------------------------------------------------------------------------
FROM scratch

COPY --from=build /src/dnscrypt-proxy/dnscrypt-proxy /usr/local/bin/
COPY --from=probe /usr/local/bin/dnsprobe /usr/local/bin/
COPY --from=build /etc/passwd /etc/group /etc/
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build --chown=nonroot:nonroot /home/nonroot /home/nonroot
COPY --from=build --chown=nonroot:nonroot /config /config

USER nonroot

ENV PATH=$PATH:/usr/local/bin

ENTRYPOINT [ "dnscrypt-proxy" ]

CMD [ "-config", "/config/dnscrypt-proxy.toml" ]
