
DOCKER_REPO := klutchell/dnscrypt-proxy
BUILD_DATE := $(strip $(shell docker run --rm busybox date -u +'%Y-%m-%dT%H:%M:%SZ'))
# BUILD_VERSION := $(strip $(shell git describe --tags --always --dirty))
BUILD_VERSION := 2.0.27
VCS_REF := $(strip $(shell git rev-parse --short HEAD))
# VCS_TAG := $(strip $(shell git describe --abbrev=0 --tags))
VCS_TAG := 2.0.27

IMAGE := ${DOCKER_REPO}:${VCS_TAG}

BUILD_OPTIONS +=

.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL := all

.PHONY: all build amd64 arm32v6 arm32v7 arm64v8 clean test push manifest help

all: amd64 arm32v6 arm32v7 arm64v8 ## Build and run tests for all platforms

build: build-amd64 build-arm32v6 build-arm64v8 ## Build for all platforms

amd64: build-amd64 test-amd64 ## Build and run tests for amd64

arm32v6: build-arm32v6 test-arm32v6 ## Build and run tests for arm32v6

arm32v7: build-arm32v7 test-arm32v7 ## Build and run tests for arm32v7

arm64v8: build-arm64v8 test-arm64v8 ## Build and run tests for arm64v8v8

clean: clean-amd64 clean-arm32v6 clean-arm32v7 clean-arm64v8 ## Remove previous builds

test: test-amd64 test-arm32v6 test-arm32v7 test-arm64v8 ## Run tests for all platforms

push: push-amd64 push-arm32v6 push-arm32v7 push-arm64v8 manifest ## Push all images to docker repo

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
		--tag ${DOCKER_REPO}:amd64-${VCS_TAG} .
	docker tag ${DOCKER_REPO}:amd64-${VCS_TAG} ${DOCKER_REPO}:amd64-latest

build-arm32v6: qemu-user-static
	docker build ${BUILD_OPTIONS} \
		--build-arg ARCH=arm32v6 \
		--build-arg GOARCH=arm \
		--build-arg GOARM=6 \
		--build-arg BUILD_VERSION \
		--build-arg BUILD_DATE \
		--build-arg VCS_REF \
		--build-arg QEMU_BINARY=qemu-arm-static \
		--tag ${DOCKER_REPO}:arm32v6-${VCS_TAG} .
	docker tag ${DOCKER_REPO}:arm32v6-${VCS_TAG} ${DOCKER_REPO}:arm32v6-latest

build-arm32v7: qemu-user-static
	docker build ${BUILD_OPTIONS} \
		--build-arg ARCH=arm32v7 \
		--build-arg GOARCH=arm \
		--build-arg GOARM=7 \
		--build-arg BUILD_VERSION \
		--build-arg BUILD_DATE \
		--build-arg VCS_REF \
		--build-arg QEMU_BINARY=qemu-arm-static \
		--tag ${DOCKER_REPO}:arm32v7-${VCS_TAG} .
	docker tag ${DOCKER_REPO}:arm32v7-${VCS_TAG} ${DOCKER_REPO}:arm32v7-latest

build-arm64v8: qemu-user-static
	docker build ${BUILD_OPTIONS} \
		--build-arg ARCH=arm64v8 \
		--build-arg GOARCH=arm64 \
		--build-arg GOARM= \
		--build-arg BUILD_VERSION \
		--build-arg BUILD_DATE \
		--build-arg VCS_REF \
		--build-arg QEMU_BINARY=qemu-aarch64-static \
		--tag ${DOCKER_REPO}:arm64v8-${VCS_TAG} .
	docker tag ${DOCKER_REPO}:arm64v8-${VCS_TAG} ${DOCKER_REPO}:arm64v8-latest

test-amd64: qemu-user-static
	docker run --rm ${DOCKER_REPO}:amd64-${VCS_TAG} /healthcheck.sh

test-arm32v6: qemu-user-static
	docker run --rm ${DOCKER_REPO}:arm32v6-${VCS_TAG} /healthcheck.sh

test-arm32v7: qemu-user-static
	docker run --rm ${DOCKER_REPO}:arm32v7-${VCS_TAG} /healthcheck.sh

test-arm64v8: qemu-user-static
	docker run --rm ${DOCKER_REPO}:arm64v8-${VCS_TAG} /healthcheck.sh

clean-amd64:
	docker image rm ${DOCKER_REPO}:amd64-${VCS_TAG}
	docker image rm ${DOCKER_REPO}:amd64-latest

clean-arm32v6:
	docker image rm ${DOCKER_REPO}:arm32v6-${VCS_TAG}
	docker image rm ${DOCKER_REPO}:arm32v6-latest

clean-arm32v7:
	docker image rm ${DOCKER_REPO}:arm32v7-${VCS_TAG}
	docker image rm ${DOCKER_REPO}:arm32v6-latest

clean-arm64v8:
	docker image rm ${DOCKER_REPO}:arm64v8-${VCS_TAG}
	docker image rm ${DOCKER_REPO}:arm64v8-latest

push-amd64:
	docker push ${DOCKER_REPO}:amd64-${VCS_TAG}
	docker push ${DOCKER_REPO}:amd64-latest

push-arm32v6:
	docker push ${DOCKER_REPO}:arm32v6-${VCS_TAG}
	docker push ${DOCKER_REPO}:arm32v6-latest

push-arm32v7:
	docker push ${DOCKER_REPO}:arm32v7-${VCS_TAG}
	docker push ${DOCKER_REPO}:arm32v7-latest

push-arm64v8:
	docker push ${DOCKER_REPO}:arm64v8-${VCS_TAG}
	docker push ${DOCKER_REPO}:arm64v8-latest

manifest:
	-docker manifest push --purge ${DOCKER_REPO}:${VCS_TAG}
	docker manifest create ${DOCKER_REPO}:${VCS_TAG} \
		${DOCKER_REPO}:amd64-${VCS_TAG} \
		${DOCKER_REPO}:arm32v6-${VCS_TAG} \
		${DOCKER_REPO}:arm32v7-${VCS_TAG} \
		${DOCKER_REPO}:arm64v8-${VCS_TAG}
	docker manifest annotate ${DOCKER_REPO}:${VCS_TAG} ${DOCKER_REPO}:arm32v6-${VCS_TAG} --os linux --arch arm --variant v6
	docker manifest annotate ${DOCKER_REPO}:${VCS_TAG} ${DOCKER_REPO}:arm32v7-${VCS_TAG} --os linux --arch arm --variant v7
	docker manifest annotate ${DOCKER_REPO}:${VCS_TAG} ${DOCKER_REPO}:arm64v8-${VCS_TAG} --os linux --arch arm64 --variant v8
	docker manifest push --purge ${DOCKER_REPO}:${VCS_TAG}
	-docker manifest push --purge ${DOCKER_REPO}:latest
	docker manifest create ${DOCKER_REPO}:latest \
		${DOCKER_REPO}:amd64-latest \
		${DOCKER_REPO}:arm32v6-latest \
		${DOCKER_REPO}:arm32v7-latest \
		${DOCKER_REPO}:arm64v8-latest
	docker manifest annotate ${DOCKER_REPO}:latest ${DOCKER_REPO}:arm32v6-latest --os linux --arch arm --variant v6
	docker manifest annotate ${DOCKER_REPO}:latest ${DOCKER_REPO}:arm32v7-latest --os linux --arch arm --variant v7
	docker manifest annotate ${DOCKER_REPO}:latest ${DOCKER_REPO}:arm64v8-latest --os linux --arch arm64 --variant v8
	docker manifest push --purge ${DOCKER_REPO}:latest

qemu-user-static:
	docker run --rm --privileged multiarch/qemu-user-static:register --reset