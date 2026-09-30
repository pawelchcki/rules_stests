#!/usr/bin/env bash
# Publish reviewed payloads, verify anonymous pulls, then update the locks.
set -euo pipefail
images="$(realpath "${1:?usage: publish_datadog_fixtures.sh IMAGE_DIRECTORY}")"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
staging="$(mktemp -d "${TMPDIR:-/tmp}/datadog-publication.XXXXXX")"
trap 'rm -rf -- "$staging"' EXIT

# Check every payload before the first registry write. Publication preserves
# the OCI manifest digest, and the subsequent pulls use no registry credentials.
for fixture in ruby gin falcon; do
  case "$fixture" in
    ruby) repository=datadog_ruby_linux_amd64; payload=sha256:b463ba27fdebf8841551f9c707ad87bc4bc504a4962c10afb3292a87ecafbe3a ;;
    gin) repository=gin_datadog_realworld_linux_amd64; payload=sha256:f2532c86ac33814c8ab87c3cc6b64d0d88ad9bdee043bc65982276adbf55e99b ;;
    falcon) repository=falcon_realworld_linux_amd64; payload=sha256:9e75306ae318163fe2dd63a4689a981fe0ac47abbabe55e827735d4618c7e543 ;;
  esac
  python3 tools/local_oci_repository.py "$images/$fixture" "$repository" --rootfs-digest "$payload"
done

for fixture in ruby gin falcon; do
  case "$fixture" in
    ruby) context=fixtures/agents/datadog-ruby; image=ghcr.io/pawelchcki/rules_stest_agents; name=datadog_ruby; tag=datadog-ruby; payload=sha256:b463ba27fdebf8841551f9c707ad87bc4bc504a4962c10afb3292a87ecafbe3a ;;
    gin) context=fixtures/apps/go/realworld-gin; image=ghcr.io/pawelchcki/rules_stest_apps; name=gin_datadog_realworld; tag=gin-datadog; payload=sha256:f2532c86ac33814c8ab87c3cc6b64d0d88ad9bdee043bc65982276adbf55e99b ;;
    falcon) context=fixtures/apps/ruby/realworld-falcon; image=ghcr.io/pawelchcki/rules_stest_apps; name=falcon_realworld; tag=falcon; payload=sha256:9e75306ae318163fe2dd63a4689a981fe0ac47abbabe55e827735d4618c7e543 ;;
  esac
  # A dirty context cannot be labelled with the committed source tree.
  test -z "$(git status --porcelain --untracked-files=all -- "$context")"
  tree="$(git rev-parse "HEAD:$context")"
  digest="$(python3 - "$images/$fixture/index.json" <<'PY'
import json, sys
print(json.load(open(sys.argv[1]))["manifests"][0]["digest"])
PY
)"
  skopeo copy --preserve-digests "oci:$images/$fixture" "docker://$image:$tag-tree-$tree-${digest#sha256:}"
  skopeo copy --src-no-creds --preserve-digests "docker://$image@$digest" "oci:$staging/$fixture"
  python3 tools/local_oci_repository.py "$staging/$fixture" "$name" --digest "$digest" --rootfs-digest "$payload"
  printf '%s %s@%s source-tree=%s\n' "$fixture" "$image" "$digest" "$tree"
  # Stage all locks until every image is anonymously readable and verified.
  if [[ ! -f "$staging/oci_images.lock.bzl" ]]; then
    cp bazel/oci_images.lock.bzl "$staging/oci_images.lock.bzl"
  fi
  python3 tools/update_oci_lock.py --lock "$staging/oci_images.lock.bzl" --name "$name" --digest "$digest" --tree "$tree"
done
cp "$staging/oci_images.lock.bzl" bazel/oci_images.lock.bzl
