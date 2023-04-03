package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net"
	"os"
	"strconv"
	"strings"
	"time"
)

const (
	defaultPort    = "53"
	defaultTimeout = 5 * time.Second
)

func main() {
	timeout := flag.Duration("timeout", defaultTimeout, "Timeout for the DNS query")
	flag.Parse()

	args := flag.Args()
	if len(args) != 2 {
		_, _ = fmt.Fprintf(os.Stderr, "Usage: %s <name> <nameserver[:port]>\n", os.Args[0])
		os.Exit(1)
	}

	hostname := args[0]
	nameserver := args[1]

	nsHost, portStr, err := net.SplitHostPort(nameserver)
	if err != nil {
		// TODO: This is a very bad way to check for an error, but `net.SplitHostPort` does not return a named error.
		// Manually checking if nameserver contains a port is harder than it seems due to having to handle v6 addresses.
		if strings.Contains(err.Error(), "missing port in address") {
			nsHost = nameserver
			portStr = defaultPort
		} else {
			log.Fatalf("Cannot parse host[:port] from %q: %v", nameserver, err)
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
				IP:   net.ParseIP(nsHost),
				Port: int(port),
			})
		},
	}

	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	addrs, err := resolver.LookupHost(ctx, hostname)
	if err != nil {
		log.Fatalf("Error looking up %q: %v", hostname, err)
	}

	if len(addrs) == 0 {
		log.Fatalf("Namserver %q did not return any result for %q", nameserver, hostname)
	}

	for _, addr := range addrs {
		fmt.Println(addr)
	}
}
