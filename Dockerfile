FROM golang:1.12 as build

ARG DNSCRYPT_PROXY_VERSION="2.0.28"
ARG DNSCRYPT_PROXY_URL="https://github.com/DNSCrypt/dnscrypt-proxy"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN curl -L "${DNSCRYPT_PROXY_URL}/archive/${DNSCRYPT_PROXY_VERSION}.tar.gz" | tar xz --strip 1 -C "${GOPATH}/src"

WORKDIR ${GOPATH}/src/dnscrypt-proxy

ENV CGO_ENABLED 0

RUN go build -v -ldflags="-s -w" -o "${GOPATH}/app/dnscrypt-proxy" \
	&& cp -av example-* "${GOPATH}/app/" \
	&& adduser --system nonroot

WORKDIR /config

COPY dnscrypt-proxy.toml ./

# ----------------------------------------------------------------------------

FROM scratch

ARG BUILD_DATE
ARG BUILD_VERSION
ARG VCS_REF

LABEL maintainer="Kyle Harding: https://klutchell.dev"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.name="klutchell/dnscrypt-proxy"
LABEL org.label-schema.description="dnscrypt-proxy is a flexible DNS proxy, with support for encrypted DNS protocols"
LABEL org.label-schema.url="https://github.com/DNSCrypt/dnscrypt-proxy"
LABEL org.label-schema.vcs-url="https://github.com/klutchell/dnscrypt-proxy"
LABEL org.label-schema.docker.cmd="docker run --rm klutchell/dnscrypt-proxy --help"
LABEL org.label-schema.build-date="${BUILD_DATE}"
LABEL org.label-schema.version="${BUILD_VERSION}"
LABEL org.label-schema.vcs-ref="${VCS_REF}"

COPY --from=build /go/app /app
COPY --from=build /config /config
COPY --from=build /etc/passwd /etc/passwd
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

USER nonroot

ENTRYPOINT ["/app/dnscrypt-proxy", "-config", "/config/dnscrypt-proxy.toml"]

RUN ["/app/dnscrypt-proxy", "-version"]
