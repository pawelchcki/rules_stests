# Reproducible Falcon fixture image

The OCI image is built for Linux/amd64 from the digest-pinned Ruby 3.3.12
builder that the Rails fixture and the Datadog Ruby payload use (the payload's
ABI must match). Bundler runs in frozen deployment mode from `Gemfile.lock`, the
request tests run during the build, and the final `FROM scratch` image contains
one normalized payload rooted at `/opt/app`.

From the repository root, prove that two clean builds produce the same OCI
manifest digest:

```sh
tools/prove_reproducible_build.sh falcon \
  fixtures/apps/ruby/realworld-falcon \
  fixtures/apps/ruby/realworld-falcon/oci/Dockerfile
```

The helper prints `digest=sha256:...` on success and removes its temporary
archives. To keep a local OCI archive, build it with the same normalization:

```sh
docker buildx build --no-cache --platform linux/amd64 \
  --provenance=false --sbom=false --build-arg SOURCE_DATE_EPOCH=0 \
  --file fixtures/apps/ruby/realworld-falcon/oci/Dockerfile \
  --output 'type=oci,dest=falcon.tar,rewrite-timestamp=true,oci-mediatypes=true,compression=gzip,force-compression=true' \
  fixtures/apps/ruby/realworld-falcon
```

The runtime is non-root; `/opt/app/seed/realworld.sqlite3` holds only the schema,
and the corpus launcher clones it into an isolated `APP_STATE_DIR` for each
test. `.github/workflows/publish-falcon.yml` uses these build settings to publish
the shared fixture and propose its updated digest lock.
