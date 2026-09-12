#!/usr/bin/env bash
# Builds only local images, verifies the reviewed manifest digests, and writes
# flags usable with `bazel --config=local`. Nothing is pushed to a registry.
set -euo pipefail
out="${1:?usage: build_datadog_fixtures.sh OUTPUT_DIRECTORY}"
mkdir -p "$out"
out="$(realpath "$out")"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
container_tool="${CONTAINER_TOOL:-podman}"
cd "$root"
: > "$out/bazel.flags"
for fixture in ruby gin; do
  if [[ "$fixture" == ruby ]]; then
    context=fixtures/agents/datadog-ruby
    repository=datadog_ruby_linux_amd64
    image=localhost/rules-stests-datadog-ruby:2.42.0
    implementation=corpus/datadog/implementation/ruby-v2.42.0.scm
  else
    context=fixtures/apps/go/realworld-gin
    repository=gin_datadog_realworld_linux_amd64
    image=localhost/rules-stests-gin-datadog:2.10.1
    implementation=corpus/datadog/implementation/go-v2.10.1.scm
  fi
  "$container_tool" build --timestamp 0 -t "$image" "$context" > "$out/$fixture.build.log" 2>&1
  "$container_tool" save --format oci-dir -o "$out/$fixture" "$image"
  digest="$(python3 -c 'import re,sys; print(re.search(r"sha256:[a-f0-9]{64}",open(sys.argv[1]).read()).group())' "$implementation")"
  python3 tools/local_oci_repository.py "$out/$fixture" "$repository" --digest "$digest" >> "$out/bazel.flags"
done
