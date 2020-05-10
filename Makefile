ifndef TAG
$(error The TAG variable is missing.)
endif

# Docker Hub namespace
HUB_NAMESPACE="invoiceninja"

# Image name
IMAGE="invoiceninja"


# Building the IN based on alpine image, tag the image.
# The 'latest' tag is also being assigned to this image.
.PHONY: build-alpine
build-alpine:
	$(info Make: Building "$(TAG)" tagged images.)
	@docker build -t ${HUB_NAMESPACE}/${IMAGE}:${TAG} --build-arg INVOICENINJA_VERSION=${TAG} --file ./alpine/Dockerfile .
	@docker tag ${HUB_NAMESPACE}/${IMAGE}:${TAG} ${HUB_NAMESPACE}/${IMAGE}:latest
	$(info Make: Done.)
