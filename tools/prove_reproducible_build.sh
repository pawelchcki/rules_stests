#!/usr/bin/env bash
# Build an OCI image twice from a clean cache and prove both builds produce the
# same manifest digest. On a mismatch, report exactly what differs so the cause
# is actionable instead of a bare digest comparison: the image config, the set
# of layers, the file metadata inside a layer, or a file's contents.
#
# Usage: prove_reproducible_build.sh <name> <context> [dockerfile]
# Prints "digest=<manifest digest>" to stdout on success.

set -euo pipefail

name="${1:?build name}"
context="${2:?build context}"
dockerfile="${3:-}"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

file_args=()
if [[ -n "${dockerfile}" ]]; then
  file_args=(--file "${dockerfile}")
fi

for build in a b; do
  docker buildx build --no-cache --platform linux/amd64 --provenance=false --sbom=false \
    "${file_args[@]}" --build-arg SOURCE_DATE_EPOCH=0 \
    --output "type=oci,dest=${work}/${name}-${build}.tar,rewrite-timestamp=true,oci-mediatypes=true,compression=gzip,force-compression=true" \
    "${context}"
done

blob() { # <build> <digest>
  printf '%s/oci-%s/blobs/sha256/%s\n' "${work}" "$1" "${2#sha256:}"
}

for build in a b; do
  mkdir -p "${work}/oci-${build}"
  tar -xf "${work}/${name}-${build}.tar" -C "${work}/oci-${build}"
  manifest="$(jq -r '.manifests[0].digest' "${work}/oci-${build}/index.json")"
  printf '%s\n' "${manifest}" >"${work}/manifest-digest-${build}"
  jq -S . "$(blob "${build}" "${manifest}")" >"${work}/manifest-${build}.json"
done

digest_a="$(cat "${work}/manifest-digest-a")"
digest_b="$(cat "${work}/manifest-digest-b")"
if [[ "${digest_a}" == "${digest_b}" ]]; then
  echo "digest=${digest_a}"
  exit 0
fi

echo "::error::two clean builds of ${name} produced different manifests: ${digest_a} != ${digest_b}"

echo "--- manifest"
diff -u "${work}/manifest-a.json" "${work}/manifest-b.json" || true

echo "--- image config"
for build in a b; do
  config="$(jq -r '.config.digest' "${work}/manifest-${build}.json")"
  jq -S . "$(blob "${build}" "${config}")" >"${work}/config-${build}.json"
done
diff -u "${work}/config-a.json" "${work}/config-b.json" || true

echo "--- layer entry metadata (mode, owner, size, name)"
for build in a b; do
  : >"${work}/entries-${build}.txt"
  while read -r layer; do
    tar -tzvf "$(blob "${build}" "${layer}")" \
      | awk '{ $4=""; $5=""; print }' >>"${work}/entries-${build}.txt"
  done < <(jq -r '.layers[].digest' "${work}/manifest-${build}.json")
done
diff -u "${work}/entries-a.txt" "${work}/entries-b.txt" | head -100 || true

echo "--- layer file contents"
for build in a b; do
  mkdir -p "${work}/root-${build}"
  while read -r layer; do
    tar -xzf "$(blob "${build}" "${layer}")" -C "${work}/root-${build}"
  done < <(jq -r '.layers[].digest' "${work}/manifest-${build}.json")
  ( cd "${work}/root-${build}" && find . -type f -print0 | sort -z | xargs -0 sha256sum ) \
    >"${work}/sums-${build}.txt"
done
diff -u "${work}/sums-a.txt" "${work}/sums-b.txt" | head -100 || true

exit 1
