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

cache_root="${DATADOG_FIXTURE_CACHE:-}"
if [[ -n "$cache_root" ]]; then
  mkdir -p "$cache_root"
  cache_root="$(realpath "$cache_root")"
fi

# Hash names, kinds, modes, symlink targets, and file bytes. Git's object ID is
# insufficient here because these contexts may contain generated or ignored
# inputs, and container builds observe executable bits and symlinks too.
fixture_cache_key() {
  context="$1"
  tool_identity="$("$container_tool" version 2>&1)"
  python3 - "$context" "$root/tools/build_datadog_fixtures.sh" \
    "$root/tools/local_oci_repository.py" "$container_tool" \
    "$container_build_network" "$tool_identity" <<'PY'
import hashlib
import os
from pathlib import Path
import stat
import sys

context, builder, validator, *values = sys.argv[1:]
h = hashlib.sha256()
for value in (builder, validator, *values):
    encoded = value.encode()
    h.update(len(encoded).to_bytes(8, "big"))
    h.update(encoded)
for helper in (Path(builder), Path(validator)):
    metadata = helper.lstat()
    h.update(oct(stat.S_IMODE(metadata.st_mode)).encode())
    h.update(helper.read_bytes())
root = Path(context)
for path in sorted([root, *root.rglob("*")], key=lambda p: os.fsencode(str(p.relative_to(root)))):
    relative = b"." if path == root else os.fsencode(str(path.relative_to(root)))
    metadata = path.lstat()
    kind = stat.S_IFMT(metadata.st_mode)
    for value in (relative, str(kind).encode(), oct(stat.S_IMODE(metadata.st_mode)).encode()):
        h.update(len(value).to_bytes(8, "big"))
        h.update(value)
    if path.is_symlink():
        value = os.fsencode(os.readlink(path))
        h.update(len(value).to_bytes(8, "big"))
        h.update(value)
    elif path.is_file():
        with path.open("rb") as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                h.update(chunk)
print(h.hexdigest())
PY
}
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

  export_dir="$out/$fixture"
  cache_entry=""
  if [[ -n "$cache_root" ]]; then
    cache_key="$(fixture_cache_key "$context")"
    cache_entry="$cache_root/$fixture-$cache_key"
    if [[ -d "$cache_entry" ]]; then
      if flag="$(python3 tools/local_oci_repository.py \
          "$cache_entry" "$repository" --rootfs-digest "$rootfs_digest" 2>"$out/$fixture.build.log")"; then
        printf 'validated fixture cache hit: %s\n' "$cache_entry" > "$out/$fixture.build.log"
        printf 'Datadog fixture cache hit: %s (reviewed payload verified)\n' "$fixture"
        printf '%s\n' "$flag" >> "$out/bazel.flags"
        continue
      fi
      rejected="$cache_root/.rejected-$fixture-$cache_key-$$"
      if ! mv "$cache_entry" "$rejected"; then
        printf 'fixture cache entry failed validation and could not be quarantined: %s\n' "$cache_entry" >&2
        exit 1
      fi
      printf 'fixture cache entry failed validation; rebuilding (quarantined at %s)\n' "$rejected" >> "$out/$fixture.build.log"
    fi
    staging="$(mktemp -d "$cache_root/.building-$fixture-$cache_key.XXXXXX")"
    export_dir="$staging/export"
    printf 'Datadog fixture cache miss: %s; building reviewed payload\n' "$fixture"
  fi

  if "$container_tool" build --timestamp 0 "${container_build_network_args[@]}" -t "$image" "$context" >> "$out/$fixture.build.log" 2>&1; then
    :
  else
    status=$?
    cat "$out/$fixture.build.log" >&2
    exit "$status"
  fi
  "$container_tool" save --format oci-dir -o "$export_dir" "$image"
  flag="$(python3 tools/local_oci_repository.py \
    "$export_dir" "$repository" --rootfs-digest "$rootfs_digest")"
  if [[ -n "$cache_entry" ]]; then
    if ! mv -T "$export_dir" "$cache_entry" 2>/dev/null; then
      # A concurrent builder may have won. Trust its entry only after applying
      # the same payload validation as any other hit.
      flag="$(python3 tools/local_oci_repository.py \
        "$cache_entry" "$repository" --rootfs-digest "$rootfs_digest")" || {
          printf 'concurrent fixture cache entry failed validation: %s\n' "$cache_entry" >&2
          exit 1
        }
    else
      flag="$(python3 tools/local_oci_repository.py \
        "$cache_entry" "$repository" --rootfs-digest "$rootfs_digest")"
    fi
    # Also discard our unused export if another builder published first.
    rm -rf -- "$staging"
  fi
  printf '%s\n' "$flag" >> "$out/bazel.flags"
done
