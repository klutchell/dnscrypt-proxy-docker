ARG NONROOT_UID=65532
ARG NONROOT_GID=65532

FROM --platform=$BUILDPLATFORM golang:1.27.3-alpine3.24@sha256:b8c9b82affbbb82a020bbcf998dad2ba9516944ac7e883524642a481a9505e9c AS build

WORKDIR /src

ARG DNSCRYPT_PROXY_VERSION=2.1.20
# https://github.com/DNSCrypt/dnscrypt-proxy/releases/tag/2.1.20
# sha256sum of https://github.com/DNSCrypt/dnscrypt-proxy/archive/2.1.20.tar.gz
ARG DNSCRYPT_PROXY_SHA256="2e6adb32e0f91cb755f1d2c060cddcc80ffca6a181bf03c90df22bbade121607"

ADD https://github.com/DNSCrypt/dnscrypt-proxy/archive/${DNSCRYPT_PROXY_VERSION}.tar.gz /tmp/dnscrypt-proxy.tar.gz

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN echo "${DNSCRYPT_PROXY_SHA256}  /tmp/dnscrypt-proxy.tar.gz" | sha256sum -c - \
	&& tar xzf /tmp/dnscrypt-proxy.tar.gz --strip 1

WORKDIR /src/dnscrypt-proxy

ARG TARGETOS TARGETARCH TARGETVARIANT

RUN --mount=type=cache,target=/home/nonroot/.cache/go-build,uid=65532,gid=65532 \
    --mount=type=cache,target=/go/pkg \
	CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH GOARM=${TARGETVARIANT#v} go build -v -ldflags="-s -w" -mod vendor

WORKDIR /config

# Copy example configs for reference and update listen address
RUN cp -a /src/dnscrypt-proxy/example-* ./ \
	&& sed -i '/^listen_addresses/s/127.0.0.1/0.0.0.0/' ./example-dnscrypt-proxy.toml

COPY config/dnscrypt-proxy.toml ./

ARG NONROOT_UID
ARG NONROOT_GID

RUN addgroup -S -g ${NONROOT_GID} nonroot \
	&& adduser -S -g nonroot -h /home/nonroot -u ${NONROOT_UID} -D -G nonroot nonroot

# ----------------------------------------------------------------------------
FROM scratch AS conf-example

# docker build . --target conf-example --output ./config
COPY --from=build /config/example-* /

# ----------------------------------------------------------------------------
FROM --platform=$BUILDPLATFORM golang:1.27.3-alpine3.24@sha256:b8c9b82affbbb82a020bbcf998dad2ba9516944ac7e883524642a481a9505e9c AS probe

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

ARG NONROOT_UID

USER ${NONROOT_UID}

ENV PATH=$PATH:/usr/local/bin

ENTRYPOINT [ "dnscrypt-proxy" ]

CMD [ "-config", "/config/dnscrypt-proxy.toml" ]
