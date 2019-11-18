DOCKER_REPO := klutchell/dnscrypt-proxy
TAG := 2.0.33

BUILD_DATE := $(strip $(shell docker run --rm busybox date -u +'%Y-%m-%dT%H:%M:%SZ'))
BUILD_VERSION := $(TAG)
VCS_REF := $(strip $(shell git describe --tags --always --dirty))

DOCKER_CLI_EXPERIMENTAL := enabled
BUILDX_INSTANCE_NAME := $(subst /,-,$(DOCKER_REPO))
EXTRA_OPTS := --load --progress plain --pull

COMPOSE_PROJECT_NAME := $(subst /,-,$(DOCKER_REPO))
COMPOSE_FILE := test/docker-compose.yml
COMPOSE_OPTIONS := -e COMPOSE_PROJECT_NAME -e COMPOSE_FILE -e DOCKER_REPO

.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL := all

.PHONY: all build test clean bootstrap binfmt help

all: build test

build: bootstrap ## build on the host architecture
	docker buildx build . \
		--build-arg BUILD_VERSION \
		--build-arg BUILD_DATE \
		--build-arg VCS_REF \
		--tag $(DOCKER_REPO):$(TAG) \
		--tag $(DOCKER_REPO):latest \
		$(EXTRA_OPTS)

test: binfmt ## test on the host architecture
	docker-compose up --force-recreate --abort-on-container-exit
	docker-compose down

clean: ## clean dangling images, containers, and build instances
	-docker-compose down
	-docker buildx rm $(BUILDX_INSTANCE_NAME)
	-docker rmi ${DOCKER_REPO}:${TAG} ${DOCKER_REPO}:latest

bootstrap: binfmt
	-docker buildx create --use --name $(BUILDX_INSTANCE_NAME)
	-docker buildx inspect --bootstrap

binfmt:
	docker run --rm --privileged aptman/qus -s -- -r
	docker run --rm --privileged aptman/qus -s -- -p

help: ## display available commands
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN (FS = ":.*?## "); (printf "\033[36m%-30s\033[0m %s\n", $$1, $$2)'