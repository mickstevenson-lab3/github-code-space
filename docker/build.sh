#!/usr/bin/env bash
set -euo pipefail

# adjust as needed
IMAGE_NAME="github-code-space-azp-agent"
DOCKERFILE_PATH="./docker/.dockerfile"
BUILD_CONTEXT="./docker"
AZP_AGENT_VERSION="4.269.0"
BUILDX_VERSION="v0.32.1"

: "${AZP_AGENT_VERSION:?AZP_AGENT_VERSION is required (e.g. 4.269.0)}"

docker build \
  --file "$DOCKERFILE_PATH" \
  --build-arg AZP_AGENT_VERSION="$AZP_AGENT_VERSION" \
  --build-arg BUILDX_VERSION="$BUILDX_VERSION" \
  --build-arg TARGETARCH="$(dpkg --print-architecture)" \
  --tag "$IMAGE_NAME:latest" \
  "$BUILD_CONTEXT"

echo "built image: $IMAGE_NAME:latest"
