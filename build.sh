#!/usr/bin/bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

FEDORA_RELEASE="${FEDORA_RELEASE:-44}"
VERSION="$(awk '/^Version:/{print $2}' claude-code.spec)"

podman build \
  --build-arg FEDORA_RELEASE="$FEDORA_RELEASE" \
  -t claude-code:latest \
  -t "claude-code:$VERSION" \
  .
