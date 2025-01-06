#!/bin/bash
#
# Quick and dirty signer
#

set -e

echo "${GPG_STAGINGPRODUCTION_SIGNING_KEY}" | gpg --import
exec debsign -k933ED8E218B6546CE433FC771BD617AC215D4D85 *.changes
