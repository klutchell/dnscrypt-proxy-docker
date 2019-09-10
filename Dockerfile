ARG ARCH=amd64

FROM alpine:3.9.2 as qemu

ARG QEMU_VERSION=4.0.0
ARG QEMU_BINARY=qemu-x86_64-static

# install curl
RUN apk add --no-cache curl=7.64.0-r2

# download qemu binary for provided arch and set execute bit
RUN curl -fsSL https://github.com/multiarch/qemu-user-static/releases/download/v${QEMU_VERSION}/${QEMU_BINARY} \
	-o /usr/bin/${QEMU_BINARY} && chmod +x /usr/bin/${QEMU_BINARY}

# ----------------------------------------------------------------------------

FROM golang:1.12.0 as gobuild

ARG GOOS=linux
ARG GOARCH=amd64
ARG GOARM
ARG CGO_ENABLED=0
ARG BUILD_VERSION=2.0.27

WORKDIR $GOPATH/src

# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# download specific release from github
RUN curl -fsSL "https://github.com/jedisct1/dnscrypt-proxy/archive/${BUILD_VERSION}.tar.gz" | tar xz --strip 1

# switch to project source
WORKDIR $GOPATH/src/dnscrypt-proxy

# cross-compile with golang
RUN go build -v -ldflags="-s -w" -o "$GOPATH/app/dnscrypt-proxy" && cp -a example-* "$GOPATH/app/"

# create directory for config files
RUN mkdir /config

# copy example config but change a few default values:
# - listen on all ipv4 interfaces
# - require dnssec from upstream servers
# - require nolog from upstream servers
RUN sed -r \
	-e "s/^(# )?listen_addresses = .+$/listen_addresses = ['0.0.0.0:53']/" \
	-e "s/^(# )?require_dnssec = .+$/require_dnssec = true/" \
	-e "s/^(# )?require_nolog = .+$/require_nolog = true/" \
	/go/app/example-dnscrypt-proxy.toml > /config/dnscrypt-proxy.toml

# ----------------------------------------------------------------------------

FROM ${ARCH}/alpine:3.9

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

# copy qemu binaries used for cross-compiling
COPY --from=qemu /usr/bin/qemu-* /usr/bin/

# copy binary and example config files from gobuild step
COPY --from=gobuild /go/app /app
COPY --from=gobuild /config /config

# copy healthcheck script to root
COPY healthcheck.sh /
RUN chmod +x healthcheck.sh

# install golang, dnscrypt, and healthcheck dependencies
RUN apk add --no-cache ca-certificates=20190108-r0 drill=1.7.0-r2

# add app to path
ENV PATH "/app:${PATH}"

# run startup script
CMD [ "dnscrypt-proxy", "-config", "/config/dnscrypt-proxy.toml" ]

# set default healthcheck interval
# HEALTHCHECK --interval=30s --retries=3 --start-period=5s --timeout=30s CMD [ "/healthcheck.sh" ]