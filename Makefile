DOCKER_REPO := klutchell/dnscrypt-proxy
TAG := 2.0.28
PLATFORM := linux/amd64,linux/arm64,linux/ppc64le,linux/s390x,linux/386,linux/arm/v7
BUILD_OPTIONS += --pull

BUILD_DATE := $(strip $(shell docker run --rm busybox date -u +'%Y-%m-%dT%H:%M:%SZ'))
BUILD_VERSION := ${TAG}-$(strip $(shell git describe --tags --always --dirty))
VCS_REF := $(strip $(shell git rev-parse HEAD))

DOCKER_CLI_EXPERIMENTAL := enabled

.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL := build

.PHONY: build all inspect help

build:	## build and test on the host OS architecture
	docker build ${BUILD_OPTIONS} \
		--build-arg BUILD_VERSION \
		--build-arg BUILD_DATE \
		--build-arg VCS_REF \
		--tag ${DOCKER_REPO} .
	docker run --rm ${DOCKER_REPO} --check

all: bootstrap ## cross-build multiarch manifest(s) with configured platforms
	docker buildx build ${BUILD_OPTIONS} \
		--platform ${PLATFORM} \
		--build-arg BUILD_VERSION \
		--build-arg BUILD_DATE \
		--build-arg VCS_REF \
		--tag ${DOCKER_REPO}:${TAG} \
		--tag ${DOCKER_REPO}:latest .

inspect: ## inspect manifest contents
	docker buildx imagetools inspect ${DOCKER_REPO}:${TAG}

bootstrap: binfmt
	-docker buildx create --use --name ci
	docker buildx inspect --bootstrap

binfmt:
	docker run --rm --privileged docker/binfmt:66f9012c56a8316f9244ffd7622d7c21c1f6f28d

help: ## display available commands
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
