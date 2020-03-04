#!/bin/bash

set -eu

# export IMAGE_ID="${REGISTRY}/${IMAGE}:${VERSION}-${TAG}"

# ============
# <qemu-support>
if [ $GOARCH == 'amd64' ]; then
  touch qemu-amd64-static
else
  curl -sL "https://github.com/multiarch/qemu-user-static/releases/download/${QEMU_VERSION}/qemu-${QEMU_ARCH}-static.tar.gz" | tar xz
  docker run --rm --privileged multiarch/qemu-user-static:register
fi
# </qemu-support>
# ============

# Login to Docker Hub.
echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin

export GO_PKG=github.com/coreos/prometheus-operator
git clone --depth=1 https://${GO_PKG}
cd prometheus-operator
GOARCH=${GOARCH} \
  CGO_ENABLED=0 \
  go build -o operator -mod=vendor \
  -ldflags="-s -X ${GO_PKG}/pkg/version.Version=${VERSION}" \
  ./cmd/operator

GOARCH=${GOARCH} \
  CGO_ENABLED=0 \
  go build -o prometheus-config-reloader -mod=vendor \
  -ldflags="-s -X ${GO_PKG}/pkg/version.Version=${VERSION}" \
  ./cmd/prometheus-config-reloader

function build_and_push_image() {
  local IMAGE=$1
  local IMAGE_ID="jessestuart/${IMAGE}:${VERSION}-${TAG}"

  local DOCKERFILE=Dockerfile
  if test $IMAGE == 'prometheus-config-reloader'; then
    DOCKERFILE=Dockerfile.config-reloader
  fi

  # Replace the repo's Dockerfile with our own.
  docker build -t ${IMAGE_ID} -f $DOCKERFILE \
    --build-arg target=$TARGET \
    --build-arg goarch=$GOARCH \
    --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
    --build-arg VCS_REF="$(git rev-parse --short HEAD)" \
    --build-arg VERSION=${VERSION} \
    .

  # Push push push
  docker push ${IMAGE_ID}
  if [ "$CIRCLE_BRANCH" = 'master' ]; then
    docker tag "${IMAGE_ID}" "${REGISTRY}/${IMAGE}:latest-${TAG}"
    docker push "${REGISTRY}/${IMAGE}:latest-${TAG}"
  fi
}

build_and_push_image prometheus-operator
build_and_push_image prometheus-config-reloader
