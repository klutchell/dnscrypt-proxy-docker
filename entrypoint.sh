#!/bin/sh

mkdir /config 2>/dev/null

if [ ! -f /config/dnscrypt-proxy.toml ]
then
    cp -av /app/example-dnscrypt-proxy.toml /config/dnscrypt-proxy.toml
fi

if [ -n "${DNSCRYPT_LISTEN_ADDRESSES}" ]
then
    sed -r "s/^(# )?(listen_addresses = ).+$/\2${DNSCRYPT_LISTEN_ADDRESSES}/" -i /config/dnscrypt-proxy.toml
fi

if [ -n "${DNSCRYPT_SERVER_NAMES}" ]
then
    sed -r "s/^(# )?(server_names = ).+$/\2${DNSCRYPT_SERVER_NAMES}/" -i /config/dnscrypt-proxy.toml
fi

if [ "$1" = "test" ]
then
    exec dnscrypt-proxy -config /config/dnscrypt-proxy.toml &
    sleep 10 && drill -p 5053 cloudflare.com @127.0.0.1 || exit 1
else
    echo "dnscrypt-proxy -config /config/dnscrypt-proxy.toml $@"
    exec dnscrypt-proxy -config /config/dnscrypt-proxy.toml $@
fi
