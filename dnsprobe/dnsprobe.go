package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"os"
	"strconv"
	"strings"
	"time"
)

const defaultPort = "53"

func main() {
	if len(os.Args) != 3 {
		_, _ = fmt.Fprintf(os.Stderr, "Usage: %s <name> <nameserver[:port]>\n", os.Args[0])
		os.Exit(1)
	}

	host, portStr, err := net.SplitHostPort(os.Args[2])
	if err != nil {
		// TODO: This is a very bad way to check for an error, but `net.SplitHostPort` does not return a named error.
		// Manually checking if os.Args[2] contains a port is harder than it seems due to having to handle v6 addresses.
		if strings.Contains(err.Error(), "missing port in address") {
			host = os.Args[2]
			portStr = defaultPort
		} else {
			log.Fatalf("Cannot parse host[:port] from %q: %v", os.Args[2], err)
		}
	}

	port, err := strconv.ParseInt(portStr, 10, 16)
	if err != nil {
		log.Fatalf("Cannot parse port %q: %v", portStr, err)
	}

	resolver := &net.Resolver{
		PreferGo:     true,
		StrictErrors: true,
		Dial: func(ctx context.Context, _, _ string) (net.Conn, error) {
			return net.DialUDP("udp", nil, &net.UDPAddr{
				IP:   net.ParseIP(host),
				Port: int(port),
			})
		},
	}

	// TODO: Make timeout configurable.
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	addrs, err := resolver.LookupHost(ctx, os.Args[1])
	if err != nil {
		log.Fatalf("Error looking up %q: %v", os.Args[1], err)
	}

	if len(addrs) == 0 {
		log.Fatalf("Lookup for %q did not return any result", os.Args[1])
	}

	for _, addr := range addrs {
		fmt.Println(addr)
	}
}
