# syntax=docker/dockerfile:1.7
ARG SOURCE_DATE_EPOCH=0
FROM ruby:3.3.12-slim-bookworm@sha256:df209d82bb55aeb26b9b08922ee22c15f19b3458455690132dc07a5c52dc1c99 AS builder
ARG SOURCE_DATE_EPOCH
ENV BUNDLE_DEPLOYMENT=1 BUNDLE_FROZEN=1 BUNDLE_PATH=/bundle SOURCE_DATE_EPOCH=0
WORKDIR /build
RUN apt-get update && apt-get install -y --no-install-recommends build-essential && rm -rf /var/lib/apt/lists/*
RUN gem install bundler -v 4.0.3 --no-document
COPY Gemfile Gemfile.lock ./
COPY vendor vendor
RUN bundle _4.0.3_ config set deployment true \
    && bundle _4.0.3_ install --jobs=4 \
    && mkdir -p /rootfs/otel-auto-instrumentation-ruby \
    && cp -a /bundle/ruby/3.3.0/. /rootfs/otel-auto-instrumentation-ruby/ \
    && cp -a vendor /rootfs/otel-auto-instrumentation-ruby/vendor
COPY activation.rb /rootfs/otel-auto-instrumentation-ruby/activation.rb
RUN test -f /rootfs/otel-auto-instrumentation-ruby/activation.rb \
    && test -d /rootfs/otel-auto-instrumentation-ruby/gems \
    && find /rootfs -xdev -exec touch -h -d @0 {} +

FROM scratch
COPY --from=builder /rootfs/ /
