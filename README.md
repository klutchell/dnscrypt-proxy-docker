# unofficial dnscrypt-proxy multiarch docker image

[![Docker Pulls](https://img.shields.io/docker/pulls/klutchell/dnscrypt-proxy.svg?style=flat-square)](https://hub.docker.com/r/klutchell/dnscrypt-proxy/)
[![Docker Stars](https://img.shields.io/docker/stars/klutchell/dnscrypt-proxy.svg?style=flat-square)](https://hub.docker.com/r/klutchell/dnscrypt-proxy/)

[dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy) is a flexible DNS proxy, with support for encrypted DNS protocols.

## Tags

These tags including rolling updates, so from time to time the associated image may change to include fixes.

- `2.0.29-beta.2`
- `2.0.29-beta.1`
- `2.0.28`, `latest`
- `2.0.27`
- `2.0.25`
- `2.0.24`
- `2.0.23`
- `2.0.22`
- `2.0.21`
- `2.0.20`
- `2.0.19`

## Architectures

Simply pulling `klutchell/dnscrypt-proxy:2.0.28` should retrieve the correct image for your arch, but you can also pull specific arch images via tags.

The architectures supported by this image are:

- `amd64-2.0.28`
- `arm32v6-2.0.28`
- `arm32v7-2.0.28`
- `arm64v8-2.0.28`
- `i386-2.0.28`
- `ppc64le-2.0.28`
- ~~`s390x-2.0.28`~~

## Deployment

```bash
# eg. run a DNS over HTTPS proxy server on port 53
docker run -p 53:5053/udp klutchell/dnscrypt-proxy

# eg. mount a custom configuration directory
docker run -p 53:5053/udp -v "/path/to/config:/config" klutchell/dnscrypt-proxy

# eg. bind directly to port 53 on the host without docker nat
docker run --network host -e "DNSCRYPT_LISTEN_ADDRESSES=['127.0.0.1:53']" --no-healthcheck klutchell/dnscrypt-proxy

# eg. use custom upstream resolvers
docker run -p 53:5053/udp -e "DNSCRYPT_SERVER_NAMES=['scaleway-fr','google','yandex','cloudflare']" klutchell/dnscrypt-proxy
```

## Parameters

- `-p 53:5053/udp` - publish udp port 5053 on the container to udp port 53 on the host
- `-v /path/to/config:/config` - (optional) mount a custom configuration directory
- `-e "DNSCRYPT_SERVER_NAMES=['scaleway-fr','google','yandex','cloudflare']"` - _(optional)_ specify a custom range of upstream [public resolvers](https://download.dnscrypt.info/dnscrypt-resolvers/v2/public-resolvers.md)
- `-e "DNSCRYPT_LISTEN_ADDRESSES=['0.0.0.0:5053']"` - _(optional)_ specify a custom range of addresses/ports for binding (note that this requires `--no-healthcheck` or a custom `--healthcheck-cmd`)

## Building

```bash
# print makefile usage
make help

# ARCH can be amd64, arm32v6, arm32v7, arm64v8, i386, ppc64le
# and is emulated on top of any host architechture with qemu
make build ARCH=arm32v6

# appending -all to the make target will run the task
# for all supported architectures and may take a long time
make build-all BUILD_OPTIONS=--no-cache
```

## Usage

Official project wiki: <https://github.com/DNSCrypt/dnscrypt-proxy/wiki>

```bash
# print general usage
docker run --rm klutchell/dnscrypt-proxy --help
```

## Author

Kyle Harding: <https://klutchell.dev>

## Contributing

Please open an issue or submit a pull request with any features, fixes, or changes.

## Acknowledgments

Original software is by the DNSCrypt project: <https://dnscrypt.info/>

## License

- klutchell/dnscrypt-proxy: [MIT License](./LICENSE)
- DNSCrypt/dnscrypt-proxy: [ISC License](https://github.com/DNSCrypt/dnscrypt-proxy/blob/master/LICENSE)
