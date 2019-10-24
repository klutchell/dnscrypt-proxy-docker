FROM golang:1.12 as build

WORKDIR ${GOPATH}/src/dnscrypt-proxy

ARG DNSCRYPT_PROXY_VERSION="2.0.28"
ARG DNSCRYPT_PROXY_URL="https://github.com/DNSCrypt/dnscrypt-proxy"

# RUN curl -L "${DNSCRYPT_PROXY_URL}/archive/${DNSCRYPT_PROXY_VERSION}.tar.gz" | tar xz --strip 1 -C "${GOPATH}/src"

ENV DEBIAN_FRONTEND noninteractive
ENV CGO_ENABLED 0

RUN apt-get update && apt-get install -qq --no-install-recommends dnsutils=1:9.11.5.P4+dfsg-5.1 \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	&& curl -L "${DNSCRYPT_PROXY_URL}/archive/${DNSCRYPT_PROXY_VERSION}.tar.gz" -o /tmp/dnscrypt-proxy.tar.gz \
	&& tar xzf /tmp/dnscrypt-proxy.tar.gz --strip 1 -C "${GOPATH}/src" \
    && go build -v -ldflags="-s -w" -o "${GOPATH}/app/dnscrypt-proxy" \
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
COPY --from=build /etc/passwd /etc/passwd
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build --chown=nonroot /config /config

USER nonroot

ENTRYPOINT ["/app/dnscrypt-proxy", "-config", "/config/dnscrypt-proxy.toml"]

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
	CMD [ "dig", "+short", "@127.0.0.1", "-p", "5053", "dnscrypt.info", "AAAA" ]

RUN ["/app/dnscrypt-proxy", "-version"]
