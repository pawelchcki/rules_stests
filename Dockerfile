# syntax=docker/dockerfile:1.7
ARG SOURCE_DATE_EPOCH=0
FROM golang:1.25-bookworm@sha256:3b4a11519ad929d1e1d261a12cff056f0c85b735253d7d861346b9c6f8b36437 AS builder
ARG SOURCE_DATE_EPOCH

# The vendored app keeps upstream's cgo mattn/go-sqlite3 driver. This immutable
# official Go builder already contains GCC, libc development files, and Git, so
# rebuilding a source-tree tag does not resolve mutable distro packages.

ENV CGO_ENABLED=1 \
    GOOS=linux \
    GOARCH=amd64 \
    GOFLAGS=-trimpath

# Pinning the instrumentation tool pins the telemetry shape, so its version is
# part of the corpus profile name (go-gin-otelbuild-v1-1-0).
ARG OTELC_VERSION=v1.1.0
RUN go install go.opentelemetry.io/otelc/tool/cmd/otelc@${OTELC_VERSION}

WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY hello.go ./
COPY common ./common
COPY users ./users
COPY articles ./articles

RUN go build -ldflags "-s -w -buildid= -linkmode external -extldflags -static" \
        -o /rootfs/opt/app/bin/realworld-gin . \
    && otelc go build -ldflags "-s -w -buildid= -linkmode external -extldflags -static" \
        -o /rootfs/opt/app/bin/realworld-gin-otel .

COPY LICENSE /rootfs/opt/app/licenses/application-LICENSE

# The OpenTelemetry resource detectors look the running UID up in the password
# database; without these entries detection fails and the resource attributes
# depend on that failure rather than on the instrumentation.
RUN mkdir -p /rootfs/data /rootfs/tmp /rootfs/etc \
    && chmod 1777 /rootfs/tmp \
    && echo 'nonroot:x:65532:65532:nonroot:/data:/sbin/nologin' >/rootfs/etc/passwd \
    && echo 'nonroot:x:65532:' >/rootfs/etc/group \
    && chown -R 65532:65532 /rootfs/data

FROM scratch
ARG SOURCE_DATE_EPOCH
COPY --from=builder /rootfs/ /
USER 65532:65532
WORKDIR /data
EXPOSE 8080
ENTRYPOINT ["/opt/app/bin/realworld-gin"]
CMD ["serve", "--host", "0.0.0.0", "--port", "8080"]
