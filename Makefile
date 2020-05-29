ifndef TAG
$(error The TAG variable is missing.)
endif

# Docker Hub namespace
HUB_NAMESPACE="invoiceninja"

# Image name
IMAGE="invoiceninja"

# Check if v5 tag is passed, so that a v5 version should be built
IS_V5=$(shell echo ${TAG} | egrep ^5)


# Building docker images based on alpine.
# Assigned tags:
#   - :alpine
#   - :alpine-<RELEASE VERSION>
.PHONY: build-alpine
build-alpine:
ifeq ($(IS_V5),)
	$(info Make: Building "$(TAG)" tagged images from alpine.)
	@docker build -t ${HUB_NAMESPACE}/${IMAGE}:alpine-${TAG} --build-arg INVOICENINJA_VERSION=${TAG} --file ./alpine/Dockerfile .
	# Tag as alpine-4
	@docker tag ${HUB_NAMESPACE}/${IMAGE}:alpine-${TAG} ${HUB_NAMESPACE}/${IMAGE}:alpine-4
	$(info Make: Done.)
endif

.PHONY: push-alpine
push-alpine:
ifeq ($(IS_V5),)
	$(info Make: Pushing tagged images from alpine.)
	@docker push ${HUB_NAMESPACE}/${IMAGE}:alpine-${TAG}
	@docker push ${HUB_NAMESPACE}/${IMAGE}:alpine-4
	$(info Make: Done.)
endif

.PHONY: build-alpine-v5
build-alpine-v5:
ifneq ($(IS_V5),)
	$(info Make: Building "$(TAG)" tagged images from alpine.)
	@docker build -t ${HUB_NAMESPACE}/${IMAGE}:${TAG} --build-arg INVOICENINJA_VERSION=${TAG} --file ./alpine/Dockerfile_v5 .
	@docker tag ${HUB_NAMESPACE}/${IMAGE}:${TAG} ${HUB_NAMESPACE}/${IMAGE}:5
	@docker tag ${HUB_NAMESPACE}/${IMAGE}:${TAG} ${HUB_NAMESPACE}/${IMAGE}:latest
	$(info Make: Done.)
endif

.PHONY: push-alpine-v5
push-alpine-v5:
ifneq ($(IS_V5),)
	$(info Make: Pushing tagged images from alpine.)
	@docker push ${HUB_NAMESPACE}/${IMAGE}:${TAG}
	@docker push ${HUB_NAMESPACE}/${IMAGE}:5
	@docker push ${HUB_NAMESPACE}/${IMAGE}:latest
endif

# Building docker images based on debian.
# Assigned tags:
#   - :latest
#   - :<RELEASE VERSION>
.PHONY: build-debian
build-debian:
ifeq ($(IS_V5),)
	$(info Make: Building "$(TAG)" tagged images from debian.)
	@docker build -t ${HUB_NAMESPACE}/${IMAGE}:${TAG} --build-arg INVOICENINJA_VERSION=${TAG} --file ./debian/Dockerfile .
	$(info Make: Done.)
endif

.PHONY: push-debian
push-debian:
ifeq ($(IS_V5),)
	$(info Make: Pushing tagged images from debian.)
	@docker push ${HUB_NAMESPACE}/${IMAGE}:${TAG}
	@docker push ${HUB_NAMESPACE}/${IMAGE}:latest
	$(info Make: Done.)
endif