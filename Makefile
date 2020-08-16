ifndef TAG
$(error The TAG variable is missing.)
endif

# Docker Hub namespace
HUB_NAMESPACE="invoiceninja"

# Image name
IMAGE="invoiceninja"

# Check if v5 tag is passed, so that a v5 version should be built
IS_V5=$(shell echo ${TAG} | egrep ^5)

# Version of Invoice Ninja. As the tag can be something like 5.0.4-p1, the version is 5.0.4.
# This supports changes to the Dockerfiles with always the same Invoice Ninja version
VERSION=$(shell echo ${TAG} | sed "s/-.*//")

# Building docker images based on alpine.
# Assigned tags:
#   - :alpine
#   - :alpine-<RELEASE VERSION>
.PHONY: build-alpine
build-alpine:
ifeq ($(IS_V5),)
	$(info Make: Building "$(VERSION)" tagged images from alpine.)
	@docker build -t ${HUB_NAMESPACE}/${IMAGE}:alpine-${VERSION} --build-arg INVOICENINJA_VERSION=${VERSION} --file ./alpine/Dockerfile .
	# Tag as alpine-4
	@docker tag ${HUB_NAMESPACE}/${IMAGE}:alpine-${VERSION} ${HUB_NAMESPACE}/${IMAGE}:alpine-4
	$(info Make: Done.)
endif

.PHONY: push-alpine
push-alpine:
ifeq ($(IS_V5),)
	$(info Make: Pushing tagged images from alpine.)
	@docker push ${HUB_NAMESPACE}/${IMAGE}:alpine-${VERSION}
	@docker push ${HUB_NAMESPACE}/${IMAGE}:alpine-4
	$(info Make: Done.)
endif

.PHONY: build-alpine-v5
build-alpine-v5:
ifneq ($(IS_V5),)
	$(info Make: Building "$(VERSION)" tagged images from alpine.)
	@docker build -t ${HUB_NAMESPACE}/${IMAGE}:${VERSION} --build-arg INVOICENINJA_VERSION=${VERSION} --file ./alpine/Dockerfile_v5 .
	@docker tag ${HUB_NAMESPACE}/${IMAGE}:${VERSION} ${HUB_NAMESPACE}/${IMAGE}:5
	@docker tag ${HUB_NAMESPACE}/${IMAGE}:${VERSION} ${HUB_NAMESPACE}/${IMAGE}:latest
	$(info Make: Done.)
endif

.PHONY: push-alpine-v5
push-alpine-v5:
ifneq ($(IS_V5),)
	$(info Make: Pushing tagged images from alpine.)
	@docker push ${HUB_NAMESPACE}/${IMAGE}:${VERSION}
	@docker push ${HUB_NAMESPACE}/${IMAGE}:5
	@docker push ${HUB_NAMESPACE}/${IMAGE}:latest
endif
