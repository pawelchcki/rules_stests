#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${BUILD_WORKSPACE_DIRECTORY:-}" ]]; then
  cd "$BUILD_WORKSPACE_DIRECTORY"
fi

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
report_ruleset_source_root="${REPORT_RULESET_SOURCE_ROOT:-}"
assemble_label="${report_ruleset}//report:assemble"

if [[ -n "$report_ruleset" && ! "$report_ruleset_source_root" =~ /blob/[0-9a-f]{40}$ ]]; then
  echo "REPORT_RULESET_SOURCE_ROOT must end in /blob/<40-character-ruleset-commit> when REPORT_RULESET is set" >&2
  exit 1
fi

report_targets=("$report_manifest" "$assemble_label")
if [[ -n "${RUBY_MATRIX_BEP:-}" ]]; then
  report_targets+=(//fixtures:ruby_matrix_report_plan //tools:embed_ruby_matrix_report)
fi

# Build and resolve every report input together. Repeated cqueries each incur
# Bazel command setup and analysis, particularly on cold CI runners.
bazel build "${bazel_flags[@]}" --remote_download_outputs=toplevel "${report_targets[@]}"
query_targets="$(IFS=' '; printf '%s' "${report_targets[*]}")"
query_format='(
  "\n".join([
    group + "\t" + f.path
    for group in ["report_manifest", "report_matrix", "report_metadata"]
    for f in getattr(providers(target)["OutputGroupInfo"], group).to_list()
  ]) if hasattr(target.output_groups, "report_manifest") else
  target.label.name + "\t" + (
    providers(target)["DefaultInfo"].files_to_run.executable.path
    if providers(target)["DefaultInfo"].files_to_run.executable else
    target.files.to_list()[0].path
  )
)'
report_files="$(bazel cquery "${bazel_flags[@]}" "config(set($query_targets), target)" \
  --output=starlark \
  --starlark:expr="$query_format")"

declare -A report_paths=()
while IFS=$'\t' read -r kind path; do
  if [[ -z "$kind" || -z "$path" || -n "${report_paths[$kind]:-}" ]]; then
    echo "invalid or duplicate report output: $kind $path" >&2
    exit 1
  fi
  report_paths[$kind]="$path"
done <<< "$report_files"
required_outputs=(assemble report_manifest report_matrix report_metadata)
if [[ -n "${RUBY_MATRIX_BEP:-}" ]]; then
  required_outputs+=(ruby_matrix_report_plan embed_ruby_matrix_report)
fi
for kind in "${required_outputs[@]}"; do
  if [[ -z "${report_paths[$kind]:-}" ]]; then
    echo "could not resolve $kind output for report assembly" >&2
    exit 1
  fi
done

execution_root="$(bazel info "${bazel_flags[@]}" execution_root)"
resolve_bazel_path() {
  local path="$1"
  if [[ "$path" == /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s/%s\n' "$execution_root" "$path"
  fi
}

assemble_path="$(resolve_bazel_path "${report_paths[assemble]}")"
manifest_path="$(resolve_bazel_path "${report_paths[report_manifest]}")"

source_root_args=()
if [[ -n "$report_ruleset_source_root" ]]; then
  source_root_args+=("--corpus-source-root=$report_ruleset_source_root")
fi

matrix_path="$(resolve_bazel_path "${report_paths[report_matrix]}")"
metadata_path="$(resolve_bazel_path "${report_paths[report_metadata]}")"

"$assemble_path" \
  --matrix="$matrix_path" \
  --metadata="$metadata_path" \
  --out=feature-parity-report.html \
  --bep=otel-profile.bep.json \
  --revision="$REPORT_REVISION" \
  --manifest="$manifest_path" \
  --execution-root="$execution_root" \
  "${source_root_args[@]}" \
  --source-root="https://github.com/${REPORT_REPOSITORY}/blob/${REPORT_REVISION}"

# Ruby API conformance keeps its normal test cache and has separate evidence
# from the fresh telemetry assertions. Consumer reports can omit this matrix.
if [[ -n "${RUBY_MATRIX_BEP:-}" ]]; then
  "$(resolve_bazel_path "${report_paths[embed_ruby_matrix_report]}")" \
    --plan="$(resolve_bazel_path "${report_paths[ruby_matrix_report_plan]}")" \
    --bep="$RUBY_MATRIX_BEP" \
    --report=feature-parity-report.html \
    --revision="$REPORT_REVISION" \
    --source-root="https://github.com/${REPORT_REPOSITORY}/blob/${REPORT_REVISION}"
fi
