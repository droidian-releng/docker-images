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

info "Building ${IMAGE}"

_sanitized=${IMAGE//-/_}
_sanitized=${_sanitized//./_}
_sanitized=${_sanitized//:/_}
_sanitized=${_sanitized////_}

ARCH=$(echo "${IMAGE}" | cut -d"/" -f1)

case "${ARCH}" in
	"arm64")
		_DOCKER_ARCH="arm64v8"
		_DOCKER_PLATFORM="linux/arm64"
		;;
	"armhf")
		_DOCKER_ARCH="arm32v7"
		_DOCKER_PLATFORM="linux/arm"
		;;
	*)
		_DOCKER_ARCH="${ARCH}"
		_DOCKER_PLATFORM="linux/${ARCH}"
		;;
esac

docker build -f "./Dockerfile.${_sanitized}" --tag "${IMAGE}" --build-arg ARCH="${_DOCKER_ARCH}" --platform ${_DOCKER_PLATFORM} --output type=docker .
