ARG ARCH=amd64

FROM alpine as qemu

RUN apk add --no-cache curl

RUN curl -fsSL https://github.com/multiarch/qemu-user-static/releases/download/v3.1.0-2/qemu-arm-static -O \
	&& chmod +x qemu-arm-static

RUN curl -fsSL https://github.com/multiarch/qemu-user-static/releases/download/v3.1.0-2/qemu-aarch64-static -O \
	&& chmod +x qemu-aarch64-static

# ----------------------------------------------------------------------------

FROM golang as gobuild

ARG GOOS=linux
ARG GOARCH=amd64
ARG GOARM
ARG BUILD_VERSION=2.0.19

WORKDIR $GOPATH/src

# download specific release from github and compile for provided arch
RUN curl -fsSL https://github.com/jedisct1/dnscrypt-proxy/archive/${BUILD_VERSION}.tar.gz | tar xz --strip 1 \
	&& cd dnscrypt-proxy && go build -ldflags="-s -w" -o $GOPATH/app/dnscrypt-proxy \
	&& cp -a example-* $GOPATH/app/

# ----------------------------------------------------------------------------

FROM ${ARCH}/alpine:3.9

ARG BUILD_DATE
ARG BUILD_VERSION
ARG VCS_REF

LABEL maintainer="kylemharding@gmail.com"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.name="klutchell/dnscrypt-proxy"
LABEL org.label-schema.description="dnscrypt-proxy is a flexible DNS proxy, with support for encrypted DNS protocols"
LABEL org.label-schema.url="https://github.com/jedisct1/dnscrypt-proxy"
LABEL org.label-schema.vcs-url="https://github.com/klutchell/dnscrypt-proxy"
LABEL org.label-schema.docker.cmd="docker run -p 53:53/tcp -p 53:53/udp klutchell/dnscrypt-proxy"
LABEL org.label-schema.build-date="${BUILD_DATE}"
LABEL org.label-schema.version="${BUILD_VERSION}"
LABEL org.label-schema.vcs-ref="${VCS_REF}"

# copy binary and example config files from gobuild step
COPY --from=gobuild /go/app /app

# add app to path
ENV PATH "/app:${PATH}"

# install qemu binaries used for cross-compiling
COPY --from=qemu qemu-arm-static qemu-aarch64-static /usr/bin/

# install go and dnscrypt dependencies
RUN apk add --no-cache libc6-compat ca-certificates

# create directory for config files
RUN mkdir /config

# copy example config and change listening addresses to all ipv4 interfaces
RUN sed -r "s/^listen_addresses = .+$/listen_addresses = ['0.0.0.0:53']/" \
	/app/example-dnscrypt-proxy.toml > /config/dnscrypt-proxy.toml

# remove qemu binaries used for cross-compiling
RUN rm /usr/bin/qemu-*-static

# expose dns ports
EXPOSE 53/tcp 53/udp

# run startup script
CMD [ "dnscrypt-proxy", "-config", "/config/dnscrypt-proxy.toml" ]