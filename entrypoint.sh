#!/bin/sh

if [ ! -f /config/dnscrypt-proxy.toml ]
then
    CONFIG=/app/example-dnscrypt-proxy.toml
else
    CONFIG=/config/dnscrypt-proxy.toml
fi

if [ -n "${DNSCRYPT_LISTEN_PORT}" ]
then
    sed -r "s/^(# )?(listen_addresses = ).+$/\2\"['0.0.0.0:${DNSCRYPT_LISTEN_PORT}']\"/" -i $CONFIG
fi

if [ -n "${DNSCRYPT_SERVER_NAMES}" ]
then
    sed -r "s/^(# )?(server_names = ).+$/\2${DNSCRYPT_SERVER_NAMES}/" -i $CONFIG
fi

if [ "$1" = "test" ]
then
    exec dnscrypt-proxy -config $CONFIG &
    sleep 10 && drill -p $DNSCRYPT_LISTEN_PORT cloudflare.com @127.0.0.1 || exit 1
else
    echo "dnscrypt-proxy -config $CONFIG"
    exec dnscrypt-proxy -config $CONFIG
fi
