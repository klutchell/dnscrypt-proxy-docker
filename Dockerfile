ARG ARCH=amd64

# ----------------------------------------------------------------------------

FROM ${ARCH}/golang:1.13.1-alpine3.10 as gobuild

ARG CGO_ENABLED=0

ENV PACKAGE_VERSION="2.0.27"
ENV PACKAGE_URL="https://github.com/jedisct1/dnscrypt-proxy"

WORKDIR ${GOPATH}/src

# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN apk add --no-cache curl=7.66.0-r0 \
	&& curl -fsSL "${PACKAGE_URL}/archive/${PACKAGE_VERSION}.tar.gz" | tar xz --strip 1

WORKDIR ${GOPATH}/src/dnscrypt-proxy

RUN go build -v -ldflags="-s -w" -o "${GOPATH}/app/dnscrypt-proxy" \
	&& cp -a example-* "${GOPATH}/app/"

# ----------------------------------------------------------------------------

FROM ${ARCH}/alpine:3.10.2

ARG BUILD_DATE
ARG BUILD_VERSION
ARG VCS_REF

LABEL maintainer="Kyle Harding: https://github.com/klutchell"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.name="klutchell/dnscrypt-proxy"
LABEL org.label-schema.description="dnscrypt-proxy is a flexible DNS proxy, with support for encrypted DNS protocols"
LABEL org.label-schema.url="https://github.com/jedisct1/dnscrypt-proxy"
LABEL org.label-schema.vcs-url="https://github.com/klutchell/dnscrypt-proxy"
LABEL org.label-schema.docker.cmd="docker run -p 53:53/tcp -p 53:53/udp klutchell/dnscrypt-proxy"
LABEL org.label-schema.build-date="${BUILD_DATE}"
LABEL org.label-schema.version="${BUILD_VERSION}"
LABEL org.label-schema.vcs-ref="${VCS_REF}"

COPY --from=gobuild /go/app /app
COPY dnscrypt-proxy.sh /

RUN apk add --no-cache ca-certificates=20190108-r0 drill=1.7.0-r2 \
	&& chmod +x /dnscrypt-proxy.sh

ENV PATH "/app:${PATH}"

EXPOSE 5053/udp

VOLUME /config

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s \
	CMD drill -p 5053 cloudflare.com @127.0.0.1 || exit 1

CMD ["/dnscrypt-proxy.sh"]