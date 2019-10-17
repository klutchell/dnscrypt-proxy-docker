#!/bin/sh

set -x

mkdir /config 2>/dev/null

[ -f /config/dnscrypt-proxy.toml ] || cp -a /app/example-dnscrypt-proxy.toml /config/dnscrypt-proxy.toml

[ -z "${DNSCRYPT_LISTEN_ADDRESSES}" ] || sed -r "s/^(# )?(listen_addresses = ).+$/\2${DNSCRYPT_LISTEN_ADDRESSES}/" -i /config/dnscrypt-proxy.toml

[ -z "${DNSCRYPT_SERVER_NAMES}" ] || sed -r "s/^(# )?(server_names = ).+$/\2${DNSCRYPT_SERVER_NAMES}/" -i /config/dnscrypt-proxy.toml

exec dnscrypt-proxy -config /config/dnscrypt-proxy.toml $@
