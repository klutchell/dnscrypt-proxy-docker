#!/bin/ash

set -e

exec /cmd.sh &

sleep 10

drill -p 5053 cloudflare.com @127.0.0.1