#!/bin/bash
#
# Quick and dirty deployer
#

if [ "${CIRCLECI}" == "true" ]; then
	# CircleCI

	BRANCH="${CIRCLE_BRANCH}"
	COMMIT="${CIRCLE_SHA1}"
	NAMESPACE="${CIRCLE_PROJECT_USERNAME}"
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
repo.droidian.org ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHsfLVXYF0IIKzWJaJ136YS5oinVQx5np+XYxSoxuk5EftNLUfPrJnbwru/6rFqPtDY2vjDaScrwJxKAYEKiYrQ=
repo.droidian.org ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDQfesvftG8KQgDF/nm/WLP4zLNf1MLRjlFJ4mMf4PiIp5o6j3hQ3qUzYsjab1/SLWZgnr2EYn/inRNDyDaWYXJR8rNxNC/GY6UKI46V/vz/9Ma1BItcupvyWk2ZaYDhovkfHYfeoIYUIlRVtgHuw97q7NOsEpYReoxKmTMZdAQcz05emkwyWfDfNTToV5gnF4GkjD9ILe/pubaUayRtaz1PmiHRkKVnzt/jUDyC/JUjnauH7sss8rFAGa84osmmKDFmmd5EO/jtUKrypYBTeyjUENl0X/hMaaAUYHxs6gdjXa2Ootk9qpYc27qUFmSb8+OIMd7tvCM2/GjOE+c9v8RpGqFc7cGe0C3SvN16VOul3KR9cdRYYTUvUz1zkRDutfUEIPThTxWejOWw80PtSH/mjc22A2R0ZX1DpgoZI21BpwZ31E/kJ6JnvBwVGUkTtj3RVnUGtIo0hKQVt2xnVhcXmT3XFTSEiW498g41lmQ286YvrVEGhJoYZjK6bA85BU=
repo.droidian.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDSa9ubsGSyyq1kpHkhLFRe0PgPtPTtm/1W7/OziZvco
EOF

# Determine target.
echo "Determining target"
if [ -n "${TAG}" ]; then
	# Tag, should go to production
	TARGET="production"
elif [[ ${BRANCH} = group/* ]]; then
	# Group
	_branch=${BRANCH/group\//}
	_branch=${_branch//./-}
	_branch=${_branch//_/-}
	_branch=${_branch//\//-}
	TARGET=$(echo group-${NAMESPACE}-${_branch} | tr '[:upper:]' '[:lower:]')
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
