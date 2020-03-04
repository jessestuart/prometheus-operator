#!/bin/sh

echo '
export GITHUB_REPO=coreos/prometheus-operator
export GOPATH=/go
export IMAGE=prometheus-operator
export REGISTRY=jessestuart

export VERSION=$(curl -s https://api.github.com/repos/${GITHUB_REPO}/releases/latest | jq -r ".tag_name")
export IMAGE_ID="${REGISTRY}/${IMAGE}:${VERSION}-${TAG}"
export DIR=$PWD
export QEMU_VERSION=$(curl -s https://api.github.com/repos/multiarch/qemu-user-static/releases/latest | jq -r ".tag_name")
' >>$BASH_ENV

. $BASH_ENV
