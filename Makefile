DOCKER_REPO := klutchell/dnscrypt-proxy
ARCH := amd64
TAG := 2.0.29-beta.2
BUILD_OPTIONS +=

BUILD_DATE := $(strip $(shell docker run --rm busybox date -u +'%Y-%m-%dT%H:%M:%SZ'))
BUILD_VERSION := ${TAG}-$(strip $(shell git describe --tags --always --dirty))
VCS_REF := $(strip $(shell git rev-parse HEAD))

.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL := build

.PHONY: build push clean all build-all push-all clean-all manifest help

build: qemu-user-static ## Build an image with the provided ARCH
	docker build ${BUILD_OPTIONS} \
		--build-arg ARCH \
		--build-arg BUILD_VERSION \
		--build-arg BUILD_DATE \
		--build-arg VCS_REF \
		--tag ${DOCKER_REPO}:${ARCH}-${TAG} .
	docker run --rm --entrypoint /bin/sh ${DOCKER_REPO}:${ARCH}-${TAG} \
		-c '(/entrypoint.sh &) && sleep 10  \
		&& drill -D -p 5053 sigok.verteiltesysteme.net @127.0.0.1 | grep NOERROR'

push: ## Push an image with the provided ARCH (requires docker login)
	docker push ${DOCKER_REPO}:${ARCH}-${TAG}

clean: ## Remove cached image with the provided ARCH
	-docker image rm ${DOCKER_REPO}:${ARCH}-${TAG}

all: build-all

build-all: ## Build images for all supported architectures
	make build ARCH=amd64
	make build ARCH=arm32v6
	make build ARCH=arm32v7`
	make build ARCH=arm64v8
	make build ARCH=i386
	make build ARCH=ppc64le

push-all: ## Push images for all supported architectures (requires docker login)
	make push ARCH=amd64
	make push ARCH=arm32v6
	make push ARCH=arm32v7
	make push ARCH=arm64v8
	make push ARCH=i386
	make push ARCH=ppc64le

clean-all: ## Clean images for all supported architectures
	make clean ARCH=amd64
	make clean ARCH=arm32v6
	make clean ARCH=arm32v7
	make clean ARCH=arm64v8
	make clean ARCH=i386
	make clean ARCH=ppc64le

manifest: ## Create and push a multiarch manifest to the docker repo (requires docker login)
	-docker manifest push --purge ${DOCKER_REPO}:${TAG}
	docker manifest create ${DOCKER_REPO}:${TAG} \
		${DOCKER_REPO}:amd64-${TAG} \
		${DOCKER_REPO}:arm32v6-${TAG} \
		${DOCKER_REPO}:arm32v7-${TAG} \
		${DOCKER_REPO}:arm64v8-${TAG} \
		${DOCKER_REPO}:i386-${TAG} \
		${DOCKER_REPO}:ppc64le-${TAG}
	docker manifest annotate ${DOCKER_REPO}:${TAG} ${DOCKER_REPO}:amd64-${TAG} --os linux --arch amd64
	docker manifest annotate ${DOCKER_REPO}:${TAG} ${DOCKER_REPO}:arm32v6-${TAG} --os linux --arch arm --variant v6
	docker manifest annotate ${DOCKER_REPO}:${TAG} ${DOCKER_REPO}:arm32v7-${TAG} --os linux --arch arm --variant v7
	docker manifest annotate ${DOCKER_REPO}:${TAG} ${DOCKER_REPO}:arm64v8-${TAG} --os linux --arch arm64 --variant v8
	docker manifest annotate ${DOCKER_REPO}:${TAG} ${DOCKER_REPO}:i386-${TAG} --os linux --arch 386
	docker manifest annotate ${DOCKER_REPO}:${TAG} ${DOCKER_REPO}:ppc64le-${TAG} --os linux --arch ppc64le
	docker manifest push --purge ${DOCKER_REPO}:${TAG}

qemu-user-static:
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

help: ## Display available commands
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
