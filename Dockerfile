FROM golang:1.12-alpine3.10 as build

WORKDIR ${GOPATH}/src/dnscrypt-proxy

ARG DNSCRYPT_PROXY_VERSION="2.0.28"
ARG DNSCRYPT_PROXY_URL="https://github.com/DNSCrypt/dnscrypt-proxy"

ENV CGO_ENABLED 0

RUN apk add --no-cache ca-certificates=20190108-r0 curl=7.66.0-r0 drill=1.7.0-r2 \
	&& curl -L "${DNSCRYPT_PROXY_URL}/archive/${DNSCRYPT_PROXY_VERSION}.tar.gz" -o /tmp/dnscrypt-proxy.tar.gz \
	&& tar xzf /tmp/dnscrypt-proxy.tar.gz --strip 1 -C "${GOPATH}/src" \
    && go build -v -ldflags="-s -w" -o "${GOPATH}/app/dnscrypt-proxy" \
	&& cp -av example-* "${GOPATH}/app/" \
	&& adduser -S nonroot

WORKDIR /config

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

COPY --from=build /go/app /app
COPY --from=build /etc/passwd /etc/passwd
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build --chown=nonroot /config /config
COPY --from=build /usr/bin/drill /usr/bin/drill
COPY --from=build /usr/lib/libldns.so.2 /usr/lib/libldns.so.2.0.0 /usr/lib/libcrypto.so.1.1 /usr/lib/
COPY --from=build /lib/libcrypto.so.1.1 /lib/ld-musl-*.so.1 /lib/libc.musl-*.so.1 /lib/

USER nonroot

ENV PATH /app:$PATH

ENTRYPOINT ["dnscrypt-proxy", "-config", "/config/dnscrypt-proxy.toml"]

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
	CMD [ "drill", "-p", "5053", "dnscrypt.info", "@127.0.0.1" ]

RUN ["dnscrypt-proxy", "-version"]
