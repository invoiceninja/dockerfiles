ifndef TAG
$(error The TAG variable is missing.)
endif

# Docker Hub namespace
HUB_NAMESPACE="invoiceninja"

# Image name
IMAGE="invoiceninja"


# Building docker images based on alpine.
# Assigned tags:
#   - :alpine
#   - :alpine-<RELEASE VERSION>
.PHONY: build-alpine
build-alpine:
	$(info Make: Building "$(TAG)" tagged images from alpine.)
	@docker build -t ${HUB_NAMESPACE}/${IMAGE}:alpine-${TAG} --build-arg INVOICENINJA_VERSION=${TAG} --file ./alpine/Dockerfile .
	@docker tag ${HUB_NAMESPACE}/${IMAGE}:alpine-${TAG} ${HUB_NAMESPACE}/${IMAGE}:alpine
	$(info Make: Done.)

.PHONY: push-alpine
push-alpine:
	$(info Make: Pushing tagged images from alpine.)
	@docker push ${HUB_NAMESPACE}/${IMAGE}:alpine-${TAG}
	@docker push ${HUB_NAMESPACE}/${IMAGE}:alpine
	$(info Make: Done.)

# Building docker images based on debian.
# Assigned tags:
#   - :latest
#   - :<RELEASE VERSION>
.PHONY: build-debian
build-debian:
	$(info Make: Building "$(TAG)" tagged images from debian.)
	@docker build -t ${HUB_NAMESPACE}/${IMAGE}:${TAG} --build-arg INVOICENINJA_VERSION=${TAG} --file ./debian/Dockerfile .
	@docker tag ${HUB_NAMESPACE}/${IMAGE}:${TAG} ${HUB_NAMESPACE}/${IMAGE}:latest
	$(info Make: Done.)

.PHONY: push-debian
push-debian:
	$(info Make: Pushing tagged images from debian.)
	@docker push ${HUB_NAMESPACE}/${IMAGE}:${TAG}
	@docker push ${HUB_NAMESPACE}/${IMAGE}:latest
	$(info Make: Done.)