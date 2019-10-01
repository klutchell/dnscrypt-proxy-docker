# unofficial dnscrypt-proxy docker image

[![Docker Pulls](https://img.shields.io/docker/pulls/klutchell/dnscrypt-proxy.svg?style=flat-square)](https://hub.docker.com/r/klutchell/dnscrypt-proxy/)
[![Docker Stars](https://img.shields.io/docker/stars/klutchell/dnscrypt-proxy.svg?style=flat-square)](https://hub.docker.com/r/klutchell/dnscrypt-proxy/)

[dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy) is a flexible DNS proxy, with support for encrypted DNS protocols.

## Tags

- `latest`, `2.0.27`
- `amd64-latest`, `amd64-2.0.27`
- `arm32v6-latest`, `arm32v6-2.0.27`
- `arm32v7-latest`, `arm32v7-2.0.27`
- `arm64v8-latest`, `arm64v8-2.0.27`
- `i386-latest`, `i386-2.0.27`
- `ppc64le-latest`, `ppc64le-2.0.27`

## Deployment

```bash
# run a DNS over HTTPS proxy server on port 53
docker run -p 53:5053/udp klutchell/dnscrypt-proxy
```

## Parameters

- `-p 53:5053/udp` - publish udp port 5053 on the container to udp port 53 on the host
- `-v /path/to/config:/config` - (optional) mount a custom configuration directory

## Building

```bash
# print makefile usage
make help

# ARCH can be amd64, arm32v6, arm32v7, arm64v8, i386, ppc64le, s390x
# and is emulated on top of any host architechture with qemu
make build ARCH=arm32v6

# appending -all to the make target will run the task
# for all supported architectures and may take a long time
make build-all BUILD_OPTIONS=--no-cache
```

## Usage

Official project wiki: <https://github.com/DNSCrypt/dnscrypt-proxy/wiki>

To use specific [public resolvers](https://download.dnscrypt.info/dnscrypt-resolvers/v2/public-resolvers.md), uncomment and change the following line in `dnscrypt-proxy.toml`.

```bash
# server_names = ['scaleway-fr', 'google', 'yandex', 'cloudflare']
```

```bash
server_names = ['quad9-dnscrypt-ip4-filter-pri']
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
