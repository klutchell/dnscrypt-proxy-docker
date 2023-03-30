# dnscrypt-proxy multiarch docker image

[![Docker Pulls](https://img.shields.io/docker/pulls/klutchell/dnscrypt-proxy.svg?style=flat-square)](https://hub.docker.com/r/klutchell/dnscrypt-proxy/)
[![Docker Stars](https://img.shields.io/docker/stars/klutchell/dnscrypt-proxy.svg?style=flat-square)](https://hub.docker.com/r/klutchell/dnscrypt-proxy/)

[dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy) is a flexible DNS proxy, with support for encrypted DNS protocols.

## Architectures

The architectures supported by this image are:

- `linux/amd64`
- `linux/arm64`
- `linux/arm/v7`
- `linux/arm/v6`

Simply pulling `klutchell/dnscrypt-proxy` should retrieve the correct image for your arch.

## Build

```bash
# enable docker buildkit and experimental mode
export DOCKER_BUILDKIT=1
export DOCKER_CLI_EXPERIMENTAL=enabled

# build local image for native platform
docker build . --tag klutchell/dnscrypt-proxy

# cross-build for another platform
docker build . --tag klutchell/dnscrypt-proxy --platform linux/arm/v7
```

## Test

```bash
# run DNS lookup on local image
docker run --rm -d --name dnscrypt klutchell/dnscrypt-proxy
docker run --rm -it --link dnscrypt uzyexe/drill -p 5053 dnscrypt.info @dnscrypt
docker stop dnscrypt
```

## Usage

Official project wiki: <https://github.com/DNSCrypt/dnscrypt-proxy/wiki>

```bash
# print version info
docker run --rm klutchell/dnscrypt-proxy --version

# print general usage
docker run --rm klutchell/dnscrypt-proxy --help

# run dnscrypt proxy server on host port 53
docker run -p 53:5053/tcp -p 53:5053/udp klutchell/dnscrypt-proxy

# run dnscrypt proxy server with configuration mounted from a host directory
# note that the files in the configuration directory '/path/to/config' must be
# readable by world, or owned by nobody:nogroup, and the directory itself must be
# writeable by world, or owned by nobody:nogroup
docker run -p 53:5053/udp -v /path/to/config:/config klutchell/dnscrypt-proxy
```

### Probes

This image includes a small DNS client called `dnsprobe` that can be used to set up health probes. `dnsprobe` is located in `/usr/local/bin/dnsprobe`.

This binary can be used as a probe to tell orchestration systems whether dnscrypt-proxy is ready to serve queries, or otherwise healthy. For example, in Kubernetes environments, liveness and readiness probes could be defined as follows:

```yaml
readinessProbe:
  timeoutSeconds: 1
  failureThreshold: 1
  periodSeconds: 5
  exec:
    command:
      - /usr/local/bin/dnsprobe
      - google.com
      - 127.0.0.1:5353
livenessProbe:
  timeoutSeconds: 3
  failureThreshold: 3
  periodSeconds: 5
  initialDelaySeconds: 30
  exec:
    command:
      - /usr/local/bin/dnsprobe
      - google.com
      - 127.0.0.1:5353
```

`dnsprobe` asks the nameserver supplied in the second argument to resolve the name supplied as the first argument. It will exit with non-zero code if:

- Any network error occurs, or the response times out after 5 seconds 
- The DNS server returns an error (e.g. `NXDOMAIN`)
- The DNS server returns an empty list of records

## Author

Kyle Harding <https://klutchell.dev>

[Buy me a beer](https://buymeacoffee.com/klutchell)

## Contributing

Please open an issue or submit a pull request with any features, fixes, or changes.

## Acknowledgments

Original software is by the DNSCrypt project: <https://dnscrypt.info/>
