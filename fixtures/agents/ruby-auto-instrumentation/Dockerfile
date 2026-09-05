# syntax=docker/dockerfile:1.7
ARG SOURCE_DATE_EPOCH=0
FROM ruby:3.3.12-slim-bookworm@sha256:df209d82bb55aeb26b9b08922ee22c15f19b3458455690132dc07a5c52dc1c99 AS builder
ARG SOURCE_DATE_EPOCH
ENV BUNDLE_DEPLOYMENT=1 BUNDLE_FROZEN=1 BUNDLE_PATH=/bundle SOURCE_DATE_EPOCH=0
WORKDIR /build
RUN sed -i \
      -e 's|URIs: http://deb.debian.org/debian$|URIs: http://snapshot.debian.org/archive/debian/20260824T000000Z|' \
      -e 's|URIs: http://deb.debian.org/debian-security$|URIs: http://snapshot.debian.org/archive/debian-security/20260824T000000Z|' \
      -e '/^Signed-By:/a Check-Valid-Until: no' \
      /etc/apt/sources.list.d/debian.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends build-essential=12.9 \
    && rm -rf /var/lib/apt/lists/*
RUN gem install bundler -v 4.0.3 --no-document
COPY Gemfile Gemfile.lock ./
COPY vendor vendor
RUN bundle _4.0.3_ config set deployment true \
    && bundle _4.0.3_ install --jobs=4 \
    && mkdir -p /rootfs/otel-auto-instrumentation-ruby \
    && cp -a /bundle/ruby/3.3.0/. /rootfs/otel-auto-instrumentation-ruby/ \
    && cp -a vendor /rootfs/otel-auto-instrumentation-ruby/vendor
COPY activation.rb /rootfs/otel-auto-instrumentation-ruby/activation.rb
# Two things here would otherwise defeat the reproducible-build check.
#
# RubyGems keeps the native-extension build logs purely as diagnostics, and both
# embed randomness: gem_make.out records the random temporary install directory
# RubyGems picks, and mkmf.log records the random object filenames GCC picks
# under /tmp. The compiled bigdecimal.so is already byte-identical between
# builds, so dropping the two logs costs nothing.
#
# Under `--jobs=4` RubyGems sometimes writes an entry from the process umask
# instead of the mode recorded in the gem, so the same file or directory comes
# out group- and world-writable in one build and not in the next. Nothing here
# is meant to be writable by group or other, so say that outright rather than
# depend on the interleaving; stripping only those bits keeps the executable
# bits that the gem binstubs rely on.
RUN test -f /rootfs/otel-auto-instrumentation-ruby/activation.rb \
    && test -d /rootfs/otel-auto-instrumentation-ruby/gems \
    && find /rootfs \( -name mkmf.log -o -name gem_make.out \) -type f -delete \
    && chmod -R go-w /rootfs \
    && find /rootfs -xdev -exec touch -h -d @0 {} +

FROM scratch
COPY --from=builder /rootfs/ /
