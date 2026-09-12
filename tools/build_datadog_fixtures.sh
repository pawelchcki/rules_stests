#!/usr/bin/env bash
# Builds only local images, verifies each exported OCI manifest, and writes
# flags usable with `bazel --config=local`. Nothing is pushed to a registry.
set -euo pipefail
out="${1:?usage: build_datadog_fixtures.sh OUTPUT_DIRECTORY}"
mkdir -p "$out"
out="$(realpath "$out")"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
container_tool="${CONTAINER_TOOL:-podman}"
container_build_network="${CONTAINER_BUILD_NETWORK:-}"
container_build_network_args=()
if [[ -n "$container_build_network" ]]; then
  container_build_network_args=(--network "$container_build_network")
fi
cd "$root"
: > "$out/bazel.flags"
# These are the uncompressed rootfs layer identities from the reviewed images
# declared by the Datadog implementation profiles. OCI envelope metadata and
# compression may vary across container-tool versions; the executed bytes may not.
for fixture in ruby gin; do
  if [[ "$fixture" == ruby ]]; then
    context=fixtures/agents/datadog-ruby
    repository=datadog_ruby_linux_amd64
    image=localhost/rules-stests-datadog-ruby:2.42.0
    rootfs_digest=sha256:29348560d9b27e8642a845e0526d7011e33b11ba7e7367d8eefbaa0fd781e21d
  else
    context=fixtures/apps/go/realworld-gin
    repository=gin_datadog_realworld_linux_amd64
    image=localhost/rules-stests-gin-datadog:2.10.1
    rootfs_digest=sha256:f2532c86ac33814c8ab87c3cc6b64d0d88ad9bdee043bc65982276adbf55e99b
  fi
  if "$container_tool" build --timestamp 0 "${container_build_network_args[@]}" -t "$image" "$context" > "$out/$fixture.build.log" 2>&1; then
    :
  else
    status=$?
    cat "$out/$fixture.build.log" >&2
    exit "$status"
  fi
  "$container_tool" save --format oci-dir -o "$out/$fixture" "$image"
  python3 tools/local_oci_repository.py \
    "$out/$fixture" "$repository" --rootfs-digest "$rootfs_digest" >> "$out/bazel.flags"
done
