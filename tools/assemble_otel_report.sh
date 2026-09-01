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

profile_targets=(
  //corpus:python_aiohttp_profile
  //corpus:python_django_profile
  //corpus:go_gin_profile
)
profiles=(go-gin-otelbuild-v1-1-0 python-aiohttp-auto-v0-65b0 python-django-auto-v0-65b0)

# Ruby integration tests stay manual until both publication workflows replace
# their immutable-image sentinels. Once locked, the same report command expands
# automatically from 39 to 52 profile scenarios.
if ! grep -q 'tree = "unpublished"' bazel/oci_images.lock.bzl; then
  profile_targets+=(//corpus:ruby_rails_profile)
  profiles+=(ruby-rails-auto-v0-1-0)
fi

bazel build "${bazel_flags[@]}" --remote_download_outputs=toplevel \
  "${profile_targets[@]}" \
  //corpus:feature_parity_generator

source_root="https://github.com/${REPORT_REPOSITORY}/blob/${REPORT_REVISION}"
args=(
  "--matrix=corpus/report/data/spec-compliance-matrix.md"
  "--metadata=corpus/report/data/catalog.json"
  "--out=feature-parity-report.html"
  "--bep=otel-profile.bep.json"
  --revision="$REPORT_REVISION"
  "--profiles=$(IFS=,; echo "${profiles[*]}")"
  "--scenarios=articles,auth,comments,errors_articles,errors_auth,errors_authorization,errors_comments,errors_profiles,favorites,feed,pagination,profiles,tags"
  --plan="go-gin-otelbuild-v1-1-0,bazel-bin/corpus/go_gin_profile.proof-plan.json,${source_root}/corpus/realworld/profiles/go-gin-otelbuild-v1-1-0.scm"
  --plan="python-aiohttp-auto-v0-65b0,bazel-bin/corpus/python_aiohttp_profile.proof-plan.json,${source_root}/corpus/realworld/profiles/python-aiohttp-auto-v0-65b0.scm"
  --plan="python-django-auto-v0-65b0,bazel-bin/corpus/python_django_profile.proof-plan.json,${source_root}/corpus/realworld/profiles/python-django-auto-v0-65b0.scm"
)

if [[ " ${profiles[*]} " == *" ruby-rails-auto-v0-1-0 "* ]]; then
  args+=(--plan="ruby-rails-auto-v0-1-0,bazel-bin/corpus/ruby_rails_profile.proof-plan.json,${source_root}/corpus/realworld/profiles/ruby-rails-auto-v0-1-0.scm")
fi

scenarios=(articles auth comments errors_articles errors_auth errors_authorization errors_comments errors_profiles favorites feed pagination profiles tags)
for profile in "${profiles[@]}"; do
  for scenario in "${scenarios[@]}"; do
    path="corpus/realworld/shapes/${profile}/${scenario}/shape.scm"
    args+=(--shape="${profile},${scenario},${path},${source_root}/${path}")
  done
done

bazel-bin/corpus/feature_parity_generator_/feature_parity_generator "${args[@]}"
