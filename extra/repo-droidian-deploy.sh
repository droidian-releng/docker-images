#!/bin/bash
#
# Quick and dirty deployer
#

if [ "${CIRCLECI}" == "true" ]; then
	# CircleCI

	BRANCH="${CIRCLE_BRANCH}"
	COMMIT="${CIRCLE_SHA1}"
	PROJECT_SLUG="${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}"
	if [ -n "${CIRCLE_TAG}" ]; then
		TAG="${CIRCLE_TAG}"
	fi
else
	# Sorry
	echo "This script runs only on CircleCI!"
	exit 1
fi

# Load SSH KEY
echo "Loading SSH key"
mkdir -p ~/.ssh

eval $(ssh-agent -s)
ssh-add <(echo "${INTAKE_SSH_KEY}") &> /dev/null

# Push fingerprint (this must be changed manually)
cat > ~/.ssh/known_hosts <<EOF
# repo.droidian.org:22 SSH-2.0-OpenSSH_9.2p1 Debian-2+deb12u2
repo.droidian.org ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2Eantp0qxTlzpyLwPIItOWNzIN56GYBFDzChZ2IpifKJhJJ4lRcGdrhHPr1k0yotuTm8jLakyp17oROVo1v1hRiDgEk8WZXPNc6ae+9WRPJ72IBE1aQmRZpttvK2FgHV8kt/8xKt49Z5lCuEIzngUuuUAHO1+ETCUEbaqZ/6TBEGlUEUbiT8stp+3MvTAVNswBXCLeLjZeWGRC86pCaO3FAYJg18uofrL8w3D3InpGnC6RLTods1tqw/2idojn7BOLZLij5hvxXI3StnWvBXWieJk1eHTsKtxF+VrnawMJmJvnQ2NMKKb16tbcj/tWGPjjtqbaH9l+RC6JLtL5VdkXf5UV30AYJx4KvXroqNjPvWPaPX3MJ/tgV/qt8ge8ugr3LhIswQ4o80v3C1mY7fv2Ugm2sz6F7Iw8PUplTYHQ7bNHrOThf3Pvi2eBz4KZtmYvFpbEfV1i8KK/Dt3RWXHnYsdOp4HUnF4y4duygHjkmsSdpJitQVHqa3sZI1OlSE=
# repo.droidian.org:22 SSH-2.0-OpenSSH_9.2p1 Debian-2+deb12u2
repo.droidian.org ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBC3+J5H2MQXCpPNRoSBnmSz/GF706qxLlksoW3FNAsXAXp0B9WzGn8hU7hqxPTY7l00CBQZJyvzMsQ4nJHs0re0=
# repo.droidian.org:22 SSH-2.0-OpenSSH_9.2p1 Debian-2+deb12u2
repo.droidian.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKwspjJbUW6RzGVMBNank8svKFBRjl9JFn4cbhmrdCC8
# repo.droidian.org:22 SSH-2.0-OpenSSH_7.9p1 Debian-10+deb10u2
repo.droidian.org ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCm8IY+RFwQNIKlQDr2vRBg9zxOzGrSFiHHekwd3zdgW3k3UgW016ArFJgeS8pQ//WqJoxMnQLh42CoWqmrVSbwxyUBAPLagulIpB5vuYDSVMm8O1MWkS7+oZHD5nujQAy4zIxnN7cMSrseUzbt/vyV0dHW+WBxlPnODMDOze/vmhVUDxvsUFi+DzCn9HvSSuViLW3dEKE8po5UP2Ttalq94luru5ZxpfAeCfJ9m4dVw+VRB66c74qtKFR7UfAQVUnOLzIlUtKnG9wrZEYilCFuPFrZVFQ92sSWdPrMjWYaeC+RzwKAscgAjTQhjUeTlb+YaAO8l94zAtE5RjjOdH1t
# repo.droidian.org:22 SSH-2.0-OpenSSH_7.9p1 Debian-10+deb10u2
repo.droidian.org ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBv8R4sZtZlwV+SPHn6hQklcWAKxQu55ESjGxSmLTqqe2DSSF6zP8x0n6dd6RyA20t6Ia8s8A/gH4W7vcpKkpDs=
# repo.droidian.org:22 SSH-2.0-OpenSSH_7.9p1 Debian-10+deb10u2
repo.droidian.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqtpEaUXN6HAi+FSbIWSywaPwTfgcXnDA4AKpNV+H+t
EOF

# Determine target.
echo "Determining target"
if [ -n "${TAG}" ]; then
	# Tag, should go to production
	TARGET="production"
elif [[ ${BRANCH} = feature/* ]]; then
	# Feature branch
	_project=${PROJECT_SLUG//\//-}
	_project=${_project//_/-}
	_branch=${BRANCH/feature\//}
	_branch=${_branch//./-}
	_branch=${_branch//_/-}
	_branch=${_branch//\//-}
	TARGET=$(echo ${_project}-${_branch} | tr '[:upper:]' '[:lower:]')
else
	# Staging
	TARGET="staging"
fi

echo "Chosen target is ${TARGET}"

echo "Uploading data"
find /tmp/buildd-results/ \
	-maxdepth 1 \
	-regextype posix-egrep \
	-regex "/tmp/buildd-results/.*\.(u?deb|tar\..*|dsc|buildinfo)$" \
	-print0 \
	| xargs -0 -i rsync --perms --chmod=D770,F770 --progress {} ${INTAKE_SSH_USER}@repo.droidian.org:./${TARGET}/

echo "Uploading .changes"
find /tmp/buildd-results/ \
	-maxdepth 1 \
	-regextype posix-egrep \
	-regex "/tmp/buildd-results/.*\.changes$" \
	-print0 \
	| xargs -0 -i rsync --perms --chmod=D770,F770 --progress {} ${INTAKE_SSH_USER}@repo.droidian.org:./${TARGET}/
