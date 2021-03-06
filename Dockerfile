ARG target
FROM golang:1.14-alpine as builder

ARG goarch
ENV GOARCH $goarch
ENV GOOS linux

ENV GOPATH /go
ENV CGO_ENABLED 0
ENV GO111MODULE on

ENV GO_PKG github.com/coreos/prometheus-operator

ARG VERSION

RUN  \
  apk add --no-cache git && \
  git clone --depth=1 https://${GO_PKG} && \
  cd prometheus-operator && \
  GOOS=${GOOS} GOARCH=${GOARCH} CGO_ENABLED=0 go build -o /bin/operator -mod=vendor -ldflags="-s -X ${GO_PKG}/pkg/version.Version=${VERSION}" ./cmd/operator

FROM $target/alpine:3.11

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL \
  maintainer="Jesse Stuart <hi@jessestuart.com>" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.url="https://hub.docker.com/r/jessestuart/prometheus-operator" \
  org.label-schema.vcs-url="https://github.com/jessestuart/prometheus-operator" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.schema-version="1.0"

COPY qemu-* /usr/bin/

COPY --from=builder /bin/operator /bin/operator

ENTRYPOINT ["/bin/operator"]
