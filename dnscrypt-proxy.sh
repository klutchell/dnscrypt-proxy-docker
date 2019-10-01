#!/bin/sh

if [ ! -f /config/dnscrypt-proxy.toml ]
then
    sed -r -e "s/^(# )?listen_addresses = .+$/listen_addresses = ['0.0.0.0:5053']/" \
	    /app/example-dnscrypt-proxy.toml > /config/dnscrypt-proxy.toml
fi

exec dnscrypt-proxy -config /config/dnscrypt-proxy.toml