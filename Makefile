# override these values at runtime as desired
# eg. make build ARCH=arm32v6 BUILD_OPTIONS=--no-cache
ARCH := amd64
DOCKER_REPO := klutchell/dnscrypt-proxy
BUILD_OPTIONS +=

# ARCH to GOARCH mapping (don't change these)
# supported ARCH values: https://github.com/docker-library/official-images#architectures-other-than-amd64
# supported GOARCH values: https://golang.org/doc/install/source#environment
ifeq "${ARCH}" "amd64"
GOARCH := amd64
GOARM :=
endif

ifeq "${ARCH}" "arm32v6"
GOARCH := arm
GOARM := 6
endif

ifeq "${ARCH}" "arm32v7"
GOARCH := arm
GOARM := 7
endif

ifeq "${ARCH}" "arm64v8"
GOARCH := arm64
GOARM :=
endif

# these values are used for container labels at build time
BUILD_DATE := $(strip $(shell docker run --rm busybox date -u +'%Y-%m-%dT%H:%M:%SZ'))
# BUILD_VERSION := $(strip $(shell git describe --tags --always --dirty))
BUILD_VERSION := 2.0.19
VCS_REF := $(strip $(shell git rev-parse --short HEAD))
# VCS_TAG := $(strip $(shell git describe --abbrev=0 --tags))
VCS_TAG = 2.0.19
DOCKER_TAG := ${VCS_TAG}-${GOARCH}

.DEFAULT_GOAL := build

.EXPORT_ALL_VARIABLES:

## -- General --

## Display this help message
.PHONY: help
help:
	@awk '{ \
			if ($$0 ~ /^.PHONY: [a-zA-Z\-\_0-9]+$$/) { \
				helpCommand = substr($$0, index($$0, ":") + 2); \
				if (helpMessage) { \
					printf "\033[36m%-20s\033[0m %s\n", \
						helpCommand, helpMessage; \
					helpMessage = ""; \
				} \
			} else if ($$0 ~ /^[a-zA-Z\-\_0-9.]+:/) { \
				helpCommand = substr($$0, 0, index($$0, ":")); \
				if (helpMessage) { \
					printf "\033[36m%-20s\033[0m %s\n", \
						helpCommand, helpMessage; \
					helpMessage = ""; \
				} \
			} else if ($$0 ~ /^##/) { \
				if (helpMessage) { \
					helpMessage = helpMessage"\n                     "substr($$0, 3); \
				} else { \
					helpMessage = substr($$0, 3); \
				} \
			} else { \
				if (helpMessage) { \
					print "\n                     "helpMessage"\n" \
				} \
				helpMessage = ""; \
			} \
		}' \
		$(MAKEFILE_LIST)

.PHONY: qemu-user-static
qemu-user-static:
	@docker run --rm --privileged multiarch/qemu-user-static:register --reset

qemu-arm-static:
	wget -q https://github.com/multiarch/qemu-user-static/releases/download/v3.1.0-2/qemu-arm-static \
	&& chmod +x qemu-arm-static

qemu-aarch64-static:
	wget -q https://github.com/multiarch/qemu-user-static/releases/download/v3.1.0-2/qemu-aarch64-static \
	&& chmod +x qemu-aarch64-static

## -- Docker --

## Build an image for the selected platform
## Usage:
##    make build [PARAM1=] [PARAM2=] [PARAM3=]
## Optional parameters:
##    ARCH               eg. amd64 or arm32v6 or arm64v8
##    BUILD_OPTIONS      eg. --no-cache
##    DOCKER_REPO        eg. myrepo/myapp
##
.PHONY: build
build: qemu-user-static
	@docker build ${BUILD_OPTIONS} \
		--build-arg ARCH \
		--build-arg GOARCH \
		--build-arg GOARM \
		--build-arg BUILD_VERSION \
		--build-arg BUILD_DATE \
		--build-arg VCS_REF \
		--tag ${DOCKER_REPO}:${DOCKER_TAG} .

## Test an image by running it locally and requesting DNSSEC lookups
## Usage:
##    make test [PARAM1=] [PARAM2=] [PARAM3=]
## Optional parameters:
##    ARCH               eg. amd64 or arm32v6 or arm64v8
##    DOCKER_REPO        eg. myrepo/myapp
##
.PHONY: test
test: qemu-user-static qemu-arm-static qemu-aarch64-static
	$(eval CONTAINER_ID=$(shell docker run --rm -d \
		-v "$(CURDIR)/qemu-arm-static:/usr/bin/qemu-arm-static" \
		-v "$(CURDIR)/qemu-aarch64-static:/usr/bin/qemu-aarch64-static" \
		-p 53:53/tcp -p 53:53/udp ${DOCKER_REPO}:${DOCKER_TAG}))
	dig sigok.verteiltesysteme.net @127.0.0.1 | grep NOERROR || (docker stop ${CONTAINER_ID}; exit 1)
	dig sigfail.verteiltesysteme.net @127.0.0.1 | grep SERVFAIL || (docker stop ${CONTAINER_ID}; exit 1)
	@docker stop ${CONTAINER_ID}

## Push an image to the selected docker repo
## Usage:
##    make push [PARAM1=] [PARAM2=] [PARAM3=]
## Optional parameters:
##    ARCH               eg. amd64 or arm32v6 or arm64v8
##    DOCKER_REPO        eg. myrepo/myapp
##
.PHONY: push
push:
	@docker push ${DOCKER_REPO}:${DOCKER_TAG}

## Create and push a multi-arch manifest list
## Usage:
##    make manifest [PARAM1=] [PARAM2=] [PARAM3=]
## Optional parameters:
##    DOCKER_REPO        eg. myrepo/myapp
##
.PHONY: manifest
manifest:
	@manifest-tool push from-args \
		--platforms linux/amd64,linux/arm,linux/arm64 \
		--template ${DOCKER_REPO}:${VCS_TAG}-ARCH \
		--target ${DOCKER_REPO}:${VCS_TAG} \
		--ignore-missing
	@manifest-tool push from-args \
		--platforms linux/amd64,linux/arm,linux/arm64 \
		--template ${DOCKER_REPO}:${VCS_TAG}-ARCH \
		--target ${DOCKER_REPO}:latest \
		--ignore-missing

## Build, test, and push the image in one step
## Usage:
##    make release [PARAM1=] [PARAM2=] [PARAM3=]
## Optional parameters:
##    ARCH               eg. amd64 or arm32v6 or arm64v8
##    BUILD_OPTIONS      eg. --no-cache
##    DOCKER_REPO        eg. myrepo/myapp
##
.PHONY: release
release: build test push
