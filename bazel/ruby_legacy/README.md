# Historical Ruby OCI descriptors

Ruby 1.9.3-p551 and 2.0.0-p648 were published only as Docker schema-1 images.
Their original manifest digests are recorded in the Ruby matrix. The checked-in
JSON files normalize those manifests to OCI descriptors for rootfs extraction:
reverse `fsLayers` into base-to-top order, retain every original layer digest
and size, and use an empty configuration object. They are filesystem fixtures,
not runnable container images.

The repository rule downloads each original blob from Docker Hub and verifies
its SHA256. The Go extractor also verifies the normalized manifest and every
layer. Full historical images are temporary extraction inputs; only Ruby,
headers, libraries and their shared-library closure become the runtime output.

If a descriptor changes, update its SHA256 in `bazel/ruby_matrix.bzl`. Do not
replace an archived runtime with an unpinned mutable tag.
