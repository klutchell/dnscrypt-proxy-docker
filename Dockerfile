FROM golang:1.12 as builder

ARG PACKAGE_VERSION="2.0.28"
ARG PACKAGE_URL="https://github.com/DNSCrypt/dnscrypt-proxy"

# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN curl -fsSL "${PACKAGE_URL}/archive/${PACKAGE_VERSION}.tar.gz" | tar xz --strip 1 -C "${GOPATH}/src"

WORKDIR ${GOPATH}/src/dnscrypt-proxy

RUN go build -v -ldflags="-s -w" -o "${GOPATH}/app/dnscrypt-proxy" \
	&& cp -av example-* "${GOPATH}/app/"

# ----------------------------------------------------------------------------

FROM gcr.io/distroless/base-debian10:nonroot

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

COPY --from=builder --chown=nonroot /go/app /app
COPY dnscrypt-proxy.toml /app

ENTRYPOINT ["/app/dnscrypt-proxy"]
