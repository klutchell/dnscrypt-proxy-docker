
DOCKER_REPO := klutchell/dnscrypt-proxy
BUILD_DATE := $(strip $(shell docker run --rm busybox date -u +'%Y-%m-%dT%H:%M:%SZ'))
# BUILD_VERSION := $(strip $(shell git describe --tags --always --dirty))
BUILD_VERSION := 2.0.23
VCS_REF := $(strip $(shell git rev-parse --short HEAD))
# VCS_TAG := $(strip $(shell git describe --abbrev=0 --tags))
VCS_TAG := 2.0.23

BUILD_OPTIONS +=

.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL := all

.PHONY: all build amd64 arm arm64 clean test push manifest help

all: amd64 arm arm64 ## Build and run tests for all platforms

build: build-amd64 build-arm build-arm64 ## Build for all platforms

amd64: build-amd64 test-amd64 ## Build and run tests for amd64

arm: build-arm test-arm ## Build and run tests for arm32v6

arm64: build-arm64 test-arm64 ## Build and run tests for arm64v8

clean: clean-amd64 clean-arm clean-arm64 ## Remove previous builds

test: test-amd64 test-arm test-arm64 ## Run tests for all platforms

push: push-amd64 push-arm push-arm64 ## Push all images to docker repo

manifest: manifest-tag manifest-latest ## Push a multi-arch manifest list

help: ## Display available commands
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build-amd64: qemu-user-static
	docker build ${BUILD_OPTIONS} \
		--build-arg ARCH=amd64 \
		--build-arg GOARCH=amd64 \
		--build-arg GOARM= \
		--build-arg BUILD_VERSION \
		--build-arg BUILD_DATE \
		--build-arg VCS_REF \
		--build-arg QEMU_BINARY=qemu-x86_64-static \
		--tag ${DOCKER_REPO}:${VCS_TAG}-amd64 .

build-arm: qemu-user-static
	docker build ${BUILD_OPTIONS} \
		--build-arg ARCH=arm32v6 \
		--build-arg GOARCH=arm \
		--build-arg GOARM=6 \
		--build-arg BUILD_VERSION \
		--build-arg BUILD_DATE \
		--build-arg VCS_REF \
		--build-arg QEMU_BINARY=qemu-arm-static \
		--tag ${DOCKER_REPO}:${VCS_TAG}-arm .

build-arm64: qemu-user-static
	docker build ${BUILD_OPTIONS} \
		--build-arg ARCH=arm64v8 \
		--build-arg GOARCH=arm64 \
		--build-arg GOARM= \
		--build-arg BUILD_VERSION \
		--build-arg BUILD_DATE \
		--build-arg VCS_REF \
		--build-arg QEMU_BINARY=qemu-aarch64-static \
		--tag ${DOCKER_REPO}:${VCS_TAG}-arm64 .

test-amd64: qemu-user-static
	docker run --rm ${DOCKER_REPO}:${VCS_TAG}-amd64 /healthcheck.sh

test-arm: qemu-user-static
	docker run --rm ${DOCKER_REPO}:${VCS_TAG}-arm /healthcheck.sh

test-arm64: qemu-user-static
	docker run --rm ${DOCKER_REPO}:${VCS_TAG}-arm64 /healthcheck.sh

clean-amd64:
	docker image rm ${DOCKER_REPO}:${VCS_TAG}-amd64

clean-arm:
	docker image rm ${DOCKER_REPO}:${VCS_TAG}-arm

clean-arm64:
	docker image rm ${DOCKER_REPO}:${VCS_TAG}-arm64

push-amd64:
	docker push ${DOCKER_REPO}:${VCS_TAG}-amd64

push-arm:
	docker push ${DOCKER_REPO}:${VCS_TAG}-arm

push-arm64:
	docker push ${DOCKER_REPO}:${VCS_TAG}-arm64

manifest-tag:
	manifest-tool push from-args \
		--platforms linux/amd64,linux/arm,linux/arm64 \
		--template ${DOCKER_REPO}:${VCS_TAG}-ARCH \
		--target ${DOCKER_REPO}:${VCS_TAG} \
		--ignore-missing

manifest-latest:
	manifest-tool push from-args \
		--platforms linux/amd64,linux/arm,linux/arm64 \
		--template ${DOCKER_REPO}:${VCS_TAG}-ARCH \
		--target ${DOCKER_REPO}:latest \
		--ignore-missing

qemu-user-static:
	docker run --rm --privileged multiarch/qemu-user-static:register --reset