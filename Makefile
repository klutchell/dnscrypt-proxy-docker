DOCKER_REPO := klutchell/dnscrypt-proxy
TAG := 2.0.33
AUTHORS := Kyle Harding <https://klutchell.dev>
SOURCE_URL := https://github.com/$(DOCKER_REPO)
DESCRIPTION := dnscrypt-proxy is a flexible DNS proxy, with support for encrypted DNS protocols

BUILD_DATE := $(strip $(shell docker run --rm busybox date -u +'%Y-%m-%dT%H:%M:%SZ'))
BUILD_VERSION := $(TAG)
VCS_REF := $(strip $(shell git describe --tags --always --dirty))

DOCKER_CLI_EXPERIMENTAL := enabled
BUILDX_INSTANCE_NAME := $(subst /,-,$(DOCKER_REPO))
BUILD_OPTS += \
		--label "org.opencontainers.image.created=$(BUILD_DATE)" \
		--label "org.opencontainers.image.authors=$(AUTHORS)" \
		--label "org.opencontainers.image.url=$(SOURCE_URL)" \
		--label "org.opencontainers.image.documentation=$(SOURCE_URL)" \
		--label "org.opencontainers.image.source=$(SOURCE_URL)" \
		--label "org.opencontainers.image.version=$(BUILD_VERSION)" \
		--label "org.opencontainers.image.revision=$(VCS_REF)" \
		--label "org.opencontainers.image.title=$(DOCKER_REPO)" \
		--label "org.opencontainers.image.description=$(DESCRIPTION)" \
		--tag $(DOCKER_REPO):$(TAG) \
		--tag $(DOCKER_REPO):latest \
		$(EXTRA_OPTS)

COMPOSE_PROJECT_NAME := $(subst /,-,$(DOCKER_REPO))
COMPOSE_FILE := test/docker-compose.yml
COMPOSE_OPTIONS := -e COMPOSE_PROJECT_NAME -e COMPOSE_FILE -e DOCKER_REPO

.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL := all

.PHONY: all build buildx test clean binfmt help

all: build test

build: ## build on the host architecture
	docker build . $(BUILD_OPTS)

buildx: binfmt ## cross-build on supported architectures
	-docker buildx create --use --name $(BUILDX_INSTANCE_NAME)
	-docker buildx inspect --bootstrap
	docker buildx build . $(BUILD_OPTS)

test: binfmt ## test on the host architecture
	docker-compose up --force-recreate --abort-on-container-exit
	docker-compose down

clean: ## clean dangling images, containers, and build instances
	-docker-compose down
	-docker buildx rm $(BUILDX_INSTANCE_NAME)
	-docker image prune --all --force --filter "label=org.opencontainers.image.title=${DOCKER_REPO}"

binfmt:
	docker run --rm --privileged aptman/qus -s -- -r
	docker run --rm --privileged aptman/qus -s -- -p

help: ## display available commands
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN (FS = ":.*?## "); (printf "\033[36m%-30s\033[0m %s\n", $$1, $$2)'