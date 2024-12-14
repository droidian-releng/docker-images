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

HOST_ARCH="$(uname -m)"
ARCH="${1}"
FLAVOUR="${2}"
[ -n "${FLAVOUR}" ] || error "USAGE: ${0} <arch> <flavour>"

info "Building Droidian base image for ${ARCH} (flavour: ${FLAVOUR})"

tmpdir="$(mktemp -d)"
onexit() {
	rm -rf ${tmpdir}
}
trap onexit EXIT

git clone https://salsa.debian.org/installer-team/debootstrap.git ${tmpdir}/debootstrap --depth 1
cp  ${tmpdir}/debootstrap/scripts/sid ${tmpdir}/debootstrap/scripts/rolling

VERSION=$(curl -L http://releases.droidian.org/snapshots/${FLAVOUR}/dists/rolling/droidian-version)

mkdir -p "base-${ARCH}-${FLAVOUR}"
DEBOOTSTRAP_DIR=${tmpdir}/debootstrap \
${tmpdir}/debootstrap/debootstrap \
	--foreign \
	--arch="${ARCH}" \
	--components=main \
	--variant=minbase \
	--include=droidian-archive-keyring,ca-certificates,droidian-release-snapshot-control,adduser \
	--keyring=keyrings/all/droidian.gpg \
	rolling \
	base-${ARCH}-${FLAVOUR} \
	http://releases.droidian.org/snapshots/${VERSION}

case "${ARCH}" in
	"arm64")
		[ "${HOST_ARCH}" == "aarch64" ] || QEMU_STATIC_EXECUTABLE="/usr/bin/qemu-aarch64-static"
		;;
	"armhf")
		[ "${HOST_ARCH}" == "arm" ] || QEMU_STATIC_EXECUTABLE="/usr/bin/qemu-arm-static"
		;;
	"amd64")
		[ "${HOST_ARCH}" == "x86_64" ] || QEMU_STATIC_EXECUTABLE="/usr/bin/qemu-x86_64-static"
		;;
	"*")
		error "Arch ${ARCH} not supported"
		;;
esac

[ -z "${QEMU_STATIC_EXECUTABLE}" ] || cp "${QEMU_STATIC_EXECUTABLE}" base-${ARCH}-${FLAVOUR}/${QEMU_STATIC_EXECUTABLE}

chroot base-${ARCH}-${FLAVOUR} \
/debootstrap/debootstrap \
	--second-stage

# Install droidian release metadata
chroot base-${ARCH}-${FLAVOUR} \
apt-get install --yes droidian-release

# Cleanup
chroot base-${ARCH}-${FLAVOUR} \
apt-get clean

[ -z "${QEMU_STATIC_EXECUTABLE}" ] || rm -f base-${ARCH}-${FLAVOUR}/${QEMU_STATIC_EXECUTABLE}

tar caf base-${ARCH}-${FLAVOUR}.tar -C base-${ARCH}-${FLAVOUR} .
rm -rf base-${ARCH}-${FLAVOUR}
