#!/usr/bin/env python3
"""Expose a retained OCI image as a local Bazel repository (no publication)."""
import argparse
import hashlib
import json
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("directory", type=Path)
parser.add_argument("repository")
parser.add_argument("--digest", required=True)
args = parser.parse_args()
index = json.loads((args.directory / "index.json").read_text())
matching = [m for m in index["manifests"] if m["digest"] == args.digest]
if len(matching) != 1:
    parser.error("OCI index does not contain exactly one expected manifest")
manifest = args.directory / "blobs" / "sha256" / args.digest.removeprefix("sha256:")
if "sha256:" + hashlib.sha256(manifest.read_bytes()).hexdigest() != args.digest:
    parser.error("manifest content digest mismatch")
index["manifests"] = matching
(args.directory / "index.json").write_text(json.dumps(index))
(args.directory / "MODULE.bazel").write_text('module(name = "local_datadog_image")\n')
(args.directory / "BUILD.bazel").write_text(
    'load(":layout.bzl", "layout")\n'
    f'layout(name = {json.dumps(args.repository)}, srcs = glob(["blobs/**", "index.json", "oci-layout"]), visibility = ["//visibility:public"])\n'
)
# Inputs participate in the action key. Local repository overrides can contain
# absolute symlinks into /tmp, which Linux sandboxing hides; this copy action is
# explicitly local. Extraction and application execution remain sandboxed.
(args.directory / "layout.bzl").write_text('''def _impl(ctx):
    output = ctx.actions.declare_directory("layout")
    args = ctx.actions.args()
    args.add(output.path)
    args.add_all(ctx.files.srcs)
    ctx.actions.run_shell(
        inputs = ctx.files.srcs,
        outputs = [output],
        arguments = [args],
        execution_requirements = {"local": "1", "no-sandbox": "1"},
        command = 'out="$1"; shift; mkdir -p "$out/blobs/sha256"; for input in "$@"; do case "$input" in */blobs/sha256/*) cp "$input" "$out/blobs/sha256/" ;; */index.json|*/oci-layout) cp "$input" "$out/" ;; esac; done',
    )
    return [DefaultInfo(files = depset([output]))]
layout = rule(implementation = _impl, attrs = {"srcs": attr.label_list(allow_files = True)})
''')
print(f"--override_repository={args.repository}={args.directory.resolve()}")
