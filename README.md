# unofficial dnscrypt-proxy docker image

[![Build Status](https://travis-ci.com/klutchell/dnscrypt-proxy.svg?branch=master)](https://travis-ci.com/klutchell/dnscrypt-proxy)
[![Docker Pulls](https://img.shields.io/docker/pulls/klutchell/dnscrypt-proxy.svg?style=flat)](https://hub.docker.com/r/klutchell/dnscrypt-proxy/)

[dnscrypt-proxy](https://github.com/jedisct1/dnscrypt-proxy) is a flexible DNS proxy, with support for encrypted DNS protocols.

## Tags

|tag|dnscrypt-proxy|image|
|---|---|---|
|`latest`|[`2.0.20`](https://github.com/jedisct1/dnscrypt-proxy/releases/tag/2.0.20)|[`manifest-v2-2`](https://docs.docker.com/registry/spec/manifest-v2-2/#manifest-list)|
|`2.0.20`|[`2.0.20`](https://github.com/jedisct1/dnscrypt-proxy/releases/tag/2.0.20)|[`manifest-v2-2`](https://docs.docker.com/registry/spec/manifest-v2-2/#manifest-list)|
|`2.0.20-amd64`|[`2.0.20`](https://github.com/jedisct1/dnscrypt-proxy/releases/tag/2.0.20)|[![](https://images.microbadger.com/badges/image/klutchell/dnscrypt-proxy:2.0.20-amd64.svg)](https://microbadger.com/images/klutchell/dnscrypt-proxy:2.0.20-amd64)|
|`2.0.20-arm`|[`2.0.20`](https://github.com/jedisct1/dnscrypt-proxy/releases/tag/2.0.20)|[![](https://images.microbadger.com/badges/image/klutchell/dnscrypt-proxy:2.0.20-arm.svg)](https://microbadger.com/images/klutchell/dnscrypt-proxy:2.0.20-arm)|
|`2.0.20-arm64`|[`2.0.20`](https://github.com/jedisct1/dnscrypt-proxy/releases/tag/2.0.20)|[![](https://images.microbadger.com/badges/image/klutchell/dnscrypt-proxy:2.0.20-arm64.svg)](https://microbadger.com/images/klutchell/dnscrypt-proxy:2.0.20-arm64)|
|`2.0.19`|[`2.0.19`](https://github.com/jedisct1/dnscrypt-proxy/releases/tag/2.0.19)|[`manifest-v2-2`](https://docs.docker.com/registry/spec/manifest-v2-2/#manifest-list)|
|`2.0.19-amd64`|[`2.0.19`](https://github.com/jedisct1/dnscrypt-proxy/releases/tag/2.0.19)|[![](https://images.microbadger.com/badges/image/klutchell/dnscrypt-proxy:2.0.19-amd64.svg)](https://microbadger.com/images/klutchell/dnscrypt-proxy:2.0.19-amd64)|
|`2.0.19-arm`|[`2.0.19`](https://github.com/jedisct1/dnscrypt-proxy/releases/tag/2.0.19)|[![](https://images.microbadger.com/badges/image/klutchell/dnscrypt-proxy:2.0.19-arm.svg)](https://microbadger.com/images/klutchell/dnscrypt-proxy:2.0.19-arm)|
|`2.0.19-arm64`|[`2.0.19`](https://github.com/jedisct1/dnscrypt-proxy/releases/tag/2.0.19)|[![](https://images.microbadger.com/badges/image/klutchell/dnscrypt-proxy:2.0.19-arm64.svg)](https://microbadger.com/images/klutchell/dnscrypt-proxy:2.0.19-arm64)|

## Deployment

```bash
docker run -p 53:53/tcp -p 53:53/udp klutchell/dnscrypt-proxy
```

## Parameters

* `-p 53:53/tcp` - expose tcp port 53 on the container to tcp port 53 on the host
* `-p 53:53/udp` - expose udp port 53 on the container to udp port 53 on the host
* `-v /path/to/config:/config` - (optional) mount a custom configuration directory

## Building

```bash
make help
make build ARCH=arm32v6
```

## Testing

```bash
make help
make test ARCH=arm32v6
```

## Usage

Check out the official dnscrypt-proxy project wiki

* https://github.com/jedisct1/dnscrypt-proxy/wiki

## Author

Kyle Harding <kylemharding@gmail.com>

## Contributing

Feel free to send an email or submit a pull request with any features, fixes, or changes!

## Acknowledgments

* https://github.com/jedisct1/dnscrypt-proxy

## License

* klutchell/dnscrypt-proxy: [MIT License](./LICENSE)
* jedisct1/dnscrypt-proxy: [ISC License](https://github.com/jedisct1/dnscrypt-proxy/blob/master/LICENSE)
