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
ARG BUILD_VERSION

WORKDIR $GOPATH/src

RUN curl -fsSL https://github.com/jedisct1/dnscrypt-proxy/archive/${BUILD_VERSION}.tar.gz | tar xvz --strip 1 \
	&& cd dnscrypt-proxy && go build -ldflags="-s -w"

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
LABEL org.label-schema.docker.cmd="docker run -p 53:53/udp klutchell/dnscrypt-proxy"
LABEL org.label-schema.build-date="${BUILD_DATE}"
LABEL org.label-schema.version="${BUILD_VERSION}"
LABEL org.label-schema.vcs-ref="${VCS_REF}"

COPY --from=qemu qemu-arm-static qemu-aarch64-static /usr/bin/
COPY --from=gobuild /go/src/dnscrypt-proxy/dnscrypt-proxy /usr/local/bin/dnscrypt-proxy
COPY --from=gobuild /go/src/dnscrypt-proxy/example-blacklist.txt /config/
COPY --from=gobuild /go/src/dnscrypt-proxy/example-cloaking-rules.txt /config/
COPY --from=gobuild /go/src/dnscrypt-proxy/example-dnscrypt-proxy.toml /config/
COPY --from=gobuild /go/src/dnscrypt-proxy/example-forwarding-rules.txt /config/
COPY --from=gobuild /go/src/dnscrypt-proxy/example-whitelist.txt /config/

RUN sed -r "s/^listen_addresses = .+$/listen_addresses = ['0.0.0.0:53']/" \
	/config/example-dnscrypt-proxy.toml > /config/dnscrypt-proxy.toml

RUN apk add --no-cache libc6-compat ca-certificates

EXPOSE 53/udp

# run startup script
CMD [ "dnscrypt-proxy", "-config", "/config/dnscrypt-proxy.toml" ]