# unofficial dnscrypt-proxy multiarch docker image

[![Docker Pulls](https://img.shields.io/docker/pulls/klutchell/dnscrypt-proxy.svg?style=flat-square)](https://hub.docker.com/r/klutchell/dnscrypt-proxy/)
[![Docker Stars](https://img.shields.io/docker/stars/klutchell/dnscrypt-proxy.svg?style=flat-square)](https://hub.docker.com/r/klutchell/dnscrypt-proxy/)

[dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy) is a flexible DNS proxy, with support for encrypted DNS protocols.

## Architectures

The architectures supported by this image are:

- `linux/amd64`
- `linux/arm64`
- `linux/ppc64le`
- `linux/386`
- `linux/arm/v7`
- `linux/arm/v6`

Simply pulling `klutchell/dnscrypt-proxy` should retrieve the correct image for your arch.

## Build

```bash
# build a local image
docker build . --pull -t klutchell/dnscrypt-proxy --build-arg "BUILD_VERSION=2.0.44"

# cross-build for another platform (eg. arm32v6)
export DOCKER_CLI_EXPERIMENTAL=enabled
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker buildx create --use --driver docker-container
docker buildx build . --pull --platform linux/arm/v6 --load -t klutchell/dnscrypt-proxy
```

## Test

```bash
# run selftest on local image
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
# note that the files must be readable by world, or owned by nobody:nogroup
docker run -p 53:5053/udp -v /path/to/config:/config klutchell/dnscrypt-proxy
```

Note that environment variables `DNSCRYPT_SERVER_NAMES` and `DNSCRYPT_LISTEN_ADDRESSES` have been depricated.
Going forward it is recommended to provide an external configuration file as shown above.

## Author

Kyle Harding <https://klutchell.dev>

[Buy me a beer](https://kyles-tip-jar.myshopify.com/cart/31356319498262:1?channel=buy_button)

[Buy me a craft beer](https://kyles-tip-jar.myshopify.com/cart/31356317859862:1?channel=buy_button)

## Contributing

Please open an issue or submit a pull request with any features, fixes, or changes.

<https://github.com/klutchell/dnscrypt-proxy/issues>

## Acknowledgments

Original software is by the DNSCrypt project: <https://dnscrypt.info/>

## License

- klutchell/dnscrypt-proxy: [MIT License](./LICENSE)
- DNSCrypt/dnscrypt-proxy: [ISC License](https://github.com/DNSCrypt/dnscrypt-proxy/blob/master/LICENSE)
