# syntax=docker/dockerfile:1.7
ARG SOURCE_DATE_EPOCH=0
FROM golang:1.25-alpine@sha256:1ae0735f00daffa3aaf1363a5184c0d2dc55c78e3db4ec70241cdac97bf84b59 AS launcher
WORKDIR /src
COPY oci/launcher.go ./launcher.go
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="-s -w -buildid=" -o /out/app ./launcher.go

FROM ruby:3.3.12-slim-bookworm@sha256:df209d82bb55aeb26b9b08922ee22c15f19b3458455690132dc07a5c52dc1c99 AS builder
ARG SOURCE_DATE_EPOCH
ENV BUNDLE_DEPLOYMENT=1 BUNDLE_FROZEN=1 BUNDLE_WITHOUT=development BUNDLE_PATH=/opt/app/bundle \
    RAILS_ENV=test SOURCE_DATE_EPOCH=0
WORKDIR /opt/app/src
RUN sed -i \
      -e 's|URIs: http://deb.debian.org/debian$|URIs: http://snapshot.debian.org/archive/debian/20260824T000000Z|' \
      -e 's|URIs: http://deb.debian.org/debian-security$|URIs: http://snapshot.debian.org/archive/debian-security/20260824T000000Z|' \
      -e '/^Signed-By:/a Check-Valid-Until: no' \
      /etc/apt/sources.list.d/debian.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      build-essential=12.9 \
      libsqlite3-dev=3.40.1-2+deb12u2 \
    && rm -rf /var/lib/apt/lists/*
RUN gem install bundler -v 4.0.3 --no-document
COPY Gemfile Gemfile.lock ./
RUN bundle _4.0.3_ config set deployment true && bundle _4.0.3_ config set without development && bundle _4.0.3_ install --jobs=4
COPY app app
COPY config config
COPY db db
COPY test test
COPY bin bin
COPY Rakefile config.ru ./
# Three things in this stage are otherwise irreproducible. The native-extension
# build logs RubyGems keeps for diagnostics embed the random temporary paths
# RubyGems and GCC pick, so they are deleted; the compiled extensions themselves
# are already deterministic. And `db:prepare` stamps wall-clock timestamps into
# the seed database's ar_internal_metadata, so they are pinned to the epoch
# alongside the existing schema_migrations rewrite. Rails only reads the
# `environment` value back, never the timestamps. And under `--jobs=4` RubyGems
# sometimes writes an entry from the process umask instead of the mode recorded
# in the gem, so group and other write bits are stripped outright; nothing here
# is meant to be writable by them, and the writable state directories get their
# access from the ownership set below.
RUN DATABASE_PATH=/tmp/realworld-test.sqlite3 bundle _4.0.3_ exec ruby bin/rails db:test:prepare \
    && DATABASE_PATH=/tmp/realworld-test.sqlite3 bundle _4.0.3_ exec ruby bin/rails test \
    && mkdir -p /rootfs/opt/app/src/tmp/cache /rootfs/opt/app/src/tmp/pids /rootfs/opt/app/src/tmp/sockets /rootfs/opt/app/seed /rootfs/opt/app/bin /rootfs/opt/app/ruby /rootfs/data /rootfs/lib /rootfs/lib64 /rootfs/usr/lib /rootfs/usr/share \
    && cp -a app bin config db Gemfile Gemfile.lock Rakefile config.ru /rootfs/opt/app/src/ \
    && cp -a /opt/app/bundle /rootfs/opt/app/bundle \
    && cp -a /usr/local/. /rootfs/opt/app/ruby/ \
    && cp -a /usr/share/zoneinfo /rootfs/usr/share/ \
    && DATABASE_PATH=/rootfs/opt/app/seed/realworld.sqlite3 RAILS_ENV=production bundle _4.0.3_ exec ruby bin/rails db:prepare \
    && bundle _4.0.3_ exec ruby -rsqlite3 -e 'p="/rootfs/opt/app/seed/realworld.sqlite3"; d=SQLite3::Database.new(p); d.execute("UPDATE schema_migrations SET version = version"); d.execute("UPDATE ar_internal_metadata SET created_at = ?, updated_at = ?", ["1970-01-01 00:00:00.000000"] * 2); d.execute("VACUUM"); d.close' \
    && cp -L /lib64/ld-linux-x86-64.so.2 /rootfs/lib64/ld-linux-x86-64.so.2 \
    && cp -a /lib/x86_64-linux-gnu /rootfs/lib/ \
    && cp -a /usr/lib/x86_64-linux-gnu /rootfs/usr/lib/ \
    && mkdir -p /rootfs/etc/ssl/certs && cp -L /etc/ssl/certs/ca-certificates.crt /rootfs/etc/ssl/certs/ \
    && find /rootfs \( -name mkmf.log -o -name gem_make.out \) -type f -delete \
    && chmod -R go-w /rootfs \
    && find /rootfs -xdev -exec touch -h -d @0 {} + \
    && chown -R 65532:65532 /rootfs/data /rootfs/opt/app/seed /rootfs/opt/app/src/tmp
COPY --from=launcher /out/app /rootfs/opt/app/bin/app

FROM scratch
COPY --from=builder /rootfs/ /
ENV APP_STATE_DIR=/data HOST=0.0.0.0 PORT=8000 RAILS_ENV=production RAILS_LOG_TO_STDOUT=1
USER 65532:65532
WORKDIR /opt/app/src
EXPOSE 8000
ENTRYPOINT ["/opt/app/bin/app"]
CMD ["server"]
