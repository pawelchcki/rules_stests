# Reproducible Falcon fixture image

The OCI image is built for Linux/amd64 from the digest-pinned Ruby 3.3.12
builder that the Rails fixture and the Datadog Ruby payload use (the payload's
ABI must match). Bundler runs in frozen deployment mode from `Gemfile.lock`, the
request tests run during the build, and the final `FROM scratch` image contains
one normalized payload rooted at `/opt/app`.

`tools/build_datadog_fixtures.sh` builds it locally and checks the reviewed
rootfs digest. The runtime is non-root; `/opt/app/seed/realworld.sqlite3` holds
only the schema, and the corpus launcher clones it into an isolated
`APP_STATE_DIR` for each test.
