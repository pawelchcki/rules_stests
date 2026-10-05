#!/usr/bin/env bash

set -euo pipefail

case "${1:-}" in
  pr)
    ruby_suite=//fixtures:ruby_ci_suite
    report_suite=//fixtures:otel_report_ci_suite
    lab_suite=//fixtures:telemetry_lab_ci_suite
    report_manifest=//fixtures:otel_report_ci_manifest
    test_filters=-otel-report,-telemetry,-ci-full
    ruby_matrix_bep=""
    ;;
  full)
    ruby_suite=//fixtures:ruby_matrix_suite
    report_suite=//fixtures:otel_report_suite
    lab_suite=//fixtures:telemetry_lab_suite
    report_manifest=//fixtures:otel_report_manifest
    test_filters=-otel-report,-telemetry
    ruby_matrix_bep=ruby-matrix.bep.json
    ;;
  *)
    echo "Usage: bash tools/run_ci.sh {pr|full}" >&2
    exit 2
    ;;
esac

REPORT_REVISION="$(git rev-parse HEAD)"
# BuildBuddy's synthetic merge has the PR head as its first parent.
if [[ "$(git show -s --format=%ce HEAD)" == "ci-runner@buildbuddy.io" ]]; then
  REPORT_REVISION="$(git rev-parse HEAD^1)"
fi
git checkout --detach "$REPORT_REVISION"

# Unstamped API/unit results stay cacheable across commits. Telemetry tests
# run only in the fresh invocation below, including the standalone labs.
# Download retained test evidence, not the executables and large runtime
# runfiles used exclusively on the remote executors.
bazel test \
  --config=buildbuddy \
  --config=ruby-matrix \
  --build_tests_only \
  --test_tag_filters="$test_filters" \
  --build_event_json_file=ruby-matrix.bep.json \
  --nobuild_event_json_file_path_conversion \
  --remote_download_outputs=minimal \
  --remote_download_regex='.*/test\.outputs(/.*)?' \
  //... \
  "$ruby_suite"

# The assembler requires evidence of --nocache_test_results because the
# report claims that its telemetry receipts came from a fresh run.
OTEL_TEST_REVISION="$REPORT_REVISION" bazel test \
  --config=buildbuddy \
  --nocache_test_results \
  --test_env=OTEL_TEST_REVISION \
  --build_event_json_file=otel-profile.bep.json \
  --nobuild_event_json_file_path_conversion \
  --remote_download_outputs=minimal \
  --remote_download_regex='.*/test\.outputs(/.*)?' \
  "$report_suite" \
  "$lab_suite"

# Only full runs embed cross-version evidence. The PR manifest describes
# exactly the base profiles and lab scenarios selected above.
REPORT_BAZEL_CONFIG=buildbuddy \
  REPORT_MANIFEST="$report_manifest" \
  RUBY_MATRIX_BEP="$ruby_matrix_bep" \
  REPORT_REPOSITORY=pawelchcki/rules_stests \
  REPORT_REVISION="$REPORT_REVISION" \
  tools/assemble_otel_report.sh

(cd examples/plugin_agent && \
  bazel test --config=buildbuddy --build_tests_only //...)
(cd examples/plugin_agent && \
  bazel build --config=buildbuddy //:otel_report_manifest)

cp feature-parity-report.html "$BUILDBUDDY_ARTIFACTS_DIRECTORY/opentelemetry-proof-report.html"
