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

bazel build "${bazel_flags[@]}" --remote_download_outputs=toplevel \
  //fixtures:otel_report_manifest \
  //report:assemble

bazel-bin/report/assemble_/assemble \
  --matrix=report/data/spec-compliance-matrix.md \
  --metadata=report/data/catalog.json \
  --out=feature-parity-report.html \
  --bep=otel-profile.bep.json \
  --revision="$REPORT_REVISION" \
  --manifest=bazel-bin/fixtures/otel_report_manifest.json \
  --source-root="https://github.com/${REPORT_REPOSITORY}/blob/${REPORT_REVISION}"
