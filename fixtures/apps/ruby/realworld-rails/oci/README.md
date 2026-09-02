# Reproducible Rails fixture image

The OCI image is built for Linux/amd64 from the digest-pinned Ruby 3.3.12
builder. Bundler runs in frozen deployment mode from `Gemfile.lock`, the Rails
request/model tests run during the build, and the final `FROM scratch` image
contains one normalized payload rooted at `/opt/app`.

Build twice and compare digests before publication:

```sh
docker buildx build --platform linux/amd64 --provenance=false --sbom=false \
  --build-arg SOURCE_DATE_EPOCH=0 --output type=oci,dest=/tmp/rails-a.tar,rewrite-timestamp=true \
  -f oci/Dockerfile .
```

The runtime is non-root. `/opt/app/seed/realworld.sqlite3` is immutable input;
the corpus launcher clones it into an isolated `APP_STATE_DIR` for each test.
