#!/bin/sh -ex

nohup sh -c 'dnscrypt-proxy -config /config/dnscrypt-proxy.toml' &

sleep 5

drill sigok.verteiltesysteme.net @127.0.0.1 | grep NOERROR
drill sigfail.verteiltesysteme.net @127.0.0.1 | grep SERVFAIL