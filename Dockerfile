ARG ARCH=amd64

FROM alpine as qemu

RUN apk add --no-cache curl

ARG QEMU_VERSION=3.1.0-2
ARG QEMU_ARCHS="arm aarch64"

RUN for i in ${QEMU_ARCHS}; \
	do \
	curl -fsSL https://github.com/multiarch/qemu-user-static/releases/download/v${QEMU_VERSION}/qemu-${i}-static.tar.gz \
	| tar zxvf - -C /usr/bin; \
	done \
	&& chmod +x /usr/bin/qemu-*

# ----------------------------------------------------------------------------

FROM golang as gobuild

ARG GOOS=linux
ARG GOARCH=amd64
ARG GOARM
ARG BUILD_VERSION=2.0.20

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
COPY --from=qemu /usr/bin/qemu-* /usr/bin/

# install go and dnscrypt dependencies
RUN apk add --no-cache libc6-compat ca-certificates

# create directory for config files
RUN mkdir /config

# copy example config and change listening addresses to all ipv4 interfaces
RUN sed -r "s/^listen_addresses = .+$/listen_addresses = ['0.0.0.0:53']/" \
	/app/example-dnscrypt-proxy.toml > /config/dnscrypt-proxy.toml

# remove qemu binaries used for cross-compiling
RUN rm /usr/bin/qemu-*

# expose dns ports
EXPOSE 53/tcp 53/udp

# run startup script
CMD [ "dnscrypt-proxy", "-config", "/config/dnscrypt-proxy.toml" ]