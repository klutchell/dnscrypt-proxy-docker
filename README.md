# unofficial dnscrypt-proxy multiarch docker image

[![Docker Pulls](https://img.shields.io/docker/pulls/klutchell/dnscrypt-proxy.svg?style=flat-square)](https://hub.docker.com/r/klutchell/dnscrypt-proxy/)
[![Docker Stars](https://img.shields.io/docker/stars/klutchell/dnscrypt-proxy.svg?style=flat-square)](https://hub.docker.com/r/klutchell/dnscrypt-proxy/)

[dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy) is a flexible DNS proxy, with support for encrypted DNS protocols.

## Tags

These tags including rolling updates, so occasionally the associated image may change to include fixes.

- `2.0.31`, `latest`
- `2.0.30`
- `2.0.29`
- `2.0.28`
- `2.0.27`
- `2.0.25`
- `2.0.24`
- `2.0.23`
- `2.0.22`
- `2.0.21`
- `2.0.20`
- `2.0.19`

## Architectures

The architectures supported by this image are:

- `linux/amd64`
- `linux/arm64`
- `linux/ppc64le`
- `linux/386`
- `linux/arm/v7`
- `linux/arm/v6`

Simply pulling `klutchell/dnscrypt-proxy` should retrieve the correct image for your arch.

## Building

```bash
# display available commands
make help

# clean dangling images, containers, and build instances
make clean

# build and test on the host architecture
make build test

# cross-build for other architectures
make build test EXTRA_OPTS=--platform=linux/arm/v7
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

# copy the example configuration files from the image to a host directory
docker run -d --name proxy --rm klutchell/dnscrypt-proxy
docker cp proxy:/config /path/to/config
docker stop proxy

# run dnscrypt proxy server with configuration mounted from a host directory
docker run -p 53:5053/udp -v /path/to/config:/config klutchell/dnscrypt-proxy
```

Note that environment variables `DNSCRYPT_SERVER_NAMES` and `DNSCRYPT_LISTEN_ADDRESSES` have been depricated.
Going forward it is recommended to provide an external configuration file as shown above.

## Author

Kyle Harding: <https://klutchell.dev>

## Contributing

Please open an issue or submit a pull request with any features, fixes, or changes.

## Acknowledgments

Original software is by the DNSCrypt project: <https://dnscrypt.info/>

## License

- klutchell/dnscrypt-proxy: [MIT License](./LICENSE)
- DNSCrypt/dnscrypt-proxy: [ISC License](https://github.com/DNSCrypt/dnscrypt-proxy/blob/master/LICENSE)
