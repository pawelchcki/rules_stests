#!/usr/bin/env bash
# Runs the parity checks whose evidence must come from fresh, retained executions.
set -euo pipefail

archive_evidence() {
  images="$1"
  evidence="$2"
  artifacts="${BUILDBUDDY_ARTIFACTS_DIRECTORY:?BuildBuddy artifact directory is required}"
  mkdir -p "$evidence/logs" "$evidence/fixture-build-logs"
  if [[ -d bazel-testlogs/fixtures ]]; then
    find -L bazel-testlogs/fixtures -name test.log -type f -exec cp -L --no-preserve=mode --parents '{}' "$evidence/logs/" \;
    find -L bazel-testlogs/fixtures -path '*/test.outputs/*' -type f -exec cp -L --no-preserve=mode --parents '{}' "$evidence/logs/" \;
  fi
  for directory in bazel-testlogs/harness examples/plugin_agent/bazel-testlogs; do
    if [[ -d "$directory" ]]; then
      find -L "$directory" -name test.log -type f -exec cp -L --no-preserve=mode --parents '{}' "$evidence/logs/" \;
    fi
  done
  if [[ -d "$images" ]]; then
    find "$images" -maxdepth 1 -name '*.build.log' -type f -exec cp -a '{}' "$evidence/fixture-build-logs/" \;
  fi
  tar -C "$(dirname "$evidence")" -czf "$artifacts/datadog-evidence.tar.gz" "$(basename "$evidence")"
}

if [[ "${1:-}" == "--archive" ]]; then
  archive_evidence "${2:-}" "${3:?usage: run_datadog_parity.sh --archive IMAGE_DIRECTORY EVIDENCE_DIRECTORY}"
  exit
fi

images="${1:?usage: run_datadog_parity.sh IMAGE_DIRECTORY REVISION EVIDENCE_DIRECTORY}"
revision="${2:?usage: run_datadog_parity.sh IMAGE_DIRECTORY REVISION EVIDENCE_DIRECTORY}"
evidence="${3:?usage: run_datadog_parity.sh IMAGE_DIRECTORY REVISION EVIDENCE_DIRECTORY}"
mkdir -p "$evidence"

mapfile -t image_flags < "$images/bazel.flags"
bazel_args=(
  --config=buildbuddy
  --spawn_strategy=remote,local
  --remote_download_outputs=all
)

bazel build "${bazel_args[@]}" "${image_flags[@]}" //tools/datadog_coverage:datadog_coverage
for execution in 1 2; do
  bazel test "${bazel_args[@]}" \
    --nocache_test_results \
    --test_env="TELEMETRY_TEST_REVISION=$revision" \
    "${image_flags[@]}" \
    //fixtures:datadog_suite
  tools/retain_datadog_evidence.py \
    --revision "$revision" \
    --output "$evidence/execution-$execution" \
    --gate bazel-bin/tools/datadog_coverage/datadog_coverage_/datadog_coverage
done

bazel test "${bazel_args[@]}" \
  --nocache_test_results \
  "${image_flags[@]}" \
  //fixtures:datadog_parallel_suite \
  --test_arg=--scenario-concurrency=4 \
  --test_arg=--scenario-repetitions=1
mkdir -p "$evidence/parallel"
find -L bazel-testlogs/fixtures -path '*/test.outputs/stress.*.json' -exec cp -L --no-preserve=mode --parents '{}' "$evidence/parallel/" \;

# This suite includes manual Rails and Gin feature probes, whose individual
# tests are intentionally absent from the wildcard full-suite expansion.
bazel test "${bazel_args[@]}" \
  --nocache_test_results \
  "${image_flags[@]}" \
  //fixtures:datadog_external_features_suite
mkdir -p "$evidence/features"
find -L bazel-testlogs/fixtures -path '*datadog_external_features*/test.outputs/*' -type f -exec cp -L --no-preserve=mode --parents '{}' "$evidence/features/" \;
