#!/usr/bin/env bash

set -euo pipefail

: "${REPORT_REVISION:?REPORT_REVISION must be a 40-character commit SHA}"
: "${REPORT_REPOSITORY:?REPORT_REPOSITORY must be an owner/repository name}"

if [[ ! "$REPORT_REVISION" =~ ^[0-9a-f]{40}$ ]]; then
  echo "REPORT_REVISION must be a lowercase 40-character commit SHA" >&2
  exit 1
fi
if [[ ! "$REPORT_REPOSITORY" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo "REPORT_REPOSITORY must be an owner/repository name" >&2
  exit 1
fi

bazel_flags=()
if [[ -n "${REPORT_BAZEL_CONFIG:-}" ]]; then
  bazel_flags+=("--config=${REPORT_BAZEL_CONFIG}")
fi

report_manifest="${REPORT_MANIFEST:-//fixtures:otel_report_manifest}"
report_ruleset="${REPORT_RULESET:-}"
assemble_label="${report_ruleset}//report:assemble"
matrix_label="${report_ruleset}//report:data/spec-compliance-matrix.md"
metadata_label="${report_ruleset}//report:data/catalog.json"

bazel build "${bazel_flags[@]}" --remote_download_outputs=toplevel \
  "$report_manifest" \
  "$assemble_label" \
  "$matrix_label" \
  "$metadata_label"

mapfile -t assemble_files < <(bazel cquery "${bazel_flags[@]}" --output=files "$assemble_label")
mapfile -t manifest_files < <(bazel cquery "${bazel_flags[@]}" --output=files "$report_manifest")
mapfile -t matrix_files < <(bazel cquery "${bazel_flags[@]}" --output=files "$matrix_label")
mapfile -t metadata_files < <(bazel cquery "${bazel_flags[@]}" --output=files "$metadata_label")

assemble_path="${assemble_files[0]}"
manifest_path=""
for path in "${manifest_files[@]}"; do
  if [[ "$path" == *".json" && "$path" != *"proof-plan.json" ]]; then
    manifest_path="$path"
    break
  fi
done
if [[ -z "$manifest_path" ]]; then
  echo "could not resolve report manifest output for $report_manifest" >&2
  exit 1
fi

"$assemble_path" \
  --matrix="${matrix_files[0]}" \
  --metadata="${metadata_files[0]}" \
  --out=feature-parity-report.html \
  --bep=otel-profile.bep.json \
  --revision="$REPORT_REVISION" \
  --manifest="$manifest_path" \
  --source-root="https://github.com/${REPORT_REPOSITORY}/blob/${REPORT_REVISION}"
