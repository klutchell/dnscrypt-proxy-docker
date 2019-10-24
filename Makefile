DOCKER_REPO := klutchell/dnscrypt-proxy
TAG := 2.0.28
PLATFORM := linux/amd64,linux/arm64,linux/ppc64le,linux/s390x,linux/386,linux/arm/v7
override BUILD_OPTIONS += --build-arg BUILD_VERSION --build-arg BUILD_DATE --build-arg VCS_REF

BUILD_DATE := $(strip $(shell docker run --rm busybox date -u +'%Y-%m-%dT%H:%M:%SZ'))
BUILD_VERSION := ${TAG}-$(strip $(shell git describe --tags --always --dirty))
VCS_REF := $(strip $(shell git rev-parse HEAD))

DOCKER_CLI_EXPERIMENTAL := enabled
BUILDX_INSTANCE := $(subst /,-,${DOCKER_REPO})
COMPOSE_PROJECT_NAME := $(subst /,-,${DOCKER_REPO})
COMPOSE_FILE := test/docker-compose.yml

.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL := build

.PHONY: build all inspect test clean bootstrap binfmt help

build: bootstrap ## build on the host OS architecture
	docker buildx build --pull --tag ${DOCKER_REPO}:${TAG} --tag ${DOCKER_REPO}:latest --load ${BUILD_OPTIONS} .

all: bootstrap ## cross-build multiarch manifest
	docker buildx build --pull --tag ${DOCKER_REPO}:${TAG} --tag ${DOCKER_REPO}:latest --platform ${PLATFORM} ${BUILD_OPTIONS} .

inspect: ## inspect manifest contents
	docker buildx imagetools inspect ${DOCKER_REPO}:${TAG}

test: binfmt ## test on the host OS architecture
	docker-compose up --force-recreate --abort-on-container-exit
	docker-compose down

clean: ## clean dangling images, containers, and build instances
	-docker-compose down
	-docker buildx rm ${BUILDX_INSTANCE}
	-docker rmi $(docker images -q ${DOCKER_REPO})

bootstrap: binfmt
	-docker buildx create --use --name ${BUILDX_INSTANCE}
	-docker buildx inspect --bootstrap

binfmt:
	docker run --rm --privileged docker/binfmt:66f9012c56a8316f9244ffd7622d7c21c1f6f28d

help: ## display available commands
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
