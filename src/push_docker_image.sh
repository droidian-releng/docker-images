#!/bin/bash

set -e

info() {
	echo "I: $@"
}

warning() {
	echo "W: $@" >&2
}

error() {
	echo "E: $@" >&2
	exit 1
}

IMAGE="${1}"
[ -n "${IMAGE}" ] || error "No image specified"

info "Pushing ${IMAGE}"

# Extract arch
ARCH=$(echo "${IMAGE}" | cut -d"/" -f1)
TARGET_TAG=quay.io/${IMAGE/"${ARCH}/"/""}-"${ARCH}"

# Handle versioned images
if [ "${2}" == "versioned" ]; then
	version="$(docker run --rm -a stdout --entrypoint cat ${IMAGE} /etc/droidian-release)"
	[ -n "${version}" ] || error "Unable to determine image version"

	TARGET_TAG=$(echo "${TARGET_TAG}" | cut -d":" -f1):"${version}-${ARCH}"
fi

echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin quay.io
docker tag "${IMAGE}" "${TARGET_TAG}"
docker push "${TARGET_TAG}"
