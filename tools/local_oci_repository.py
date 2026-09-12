#!/usr/bin/env python3
"""Expose a retained OCI image as a local Bazel repository (no publication)."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("directory", type=Path)
parser.add_argument("repository")
parser.add_argument("--digest", help="require this retained manifest digest")
parser.add_argument("--rootfs-digest", help="require this single-layer rootfs diff ID")
args = parser.parse_args()
index = json.loads((args.directory / "index.json").read_text())
manifests = index["manifests"]
if args.digest:
    manifests = [manifest for manifest in manifests if manifest["digest"] == args.digest]
if len(manifests) != 1:
    parser.error("OCI index does not contain exactly one manifest")
manifest_digest = manifests[0]["digest"]
manifest = args.directory / "blobs" / "sha256" / manifest_digest.removeprefix("sha256:")
if "sha256:" + hashlib.sha256(manifest.read_bytes()).hexdigest() != manifest_digest:
    parser.error("manifest content digest mismatch")
if args.rootfs_digest:
    manifest_document = json.loads(manifest.read_text())
    config_digest = manifest_document["config"]["digest"]
    config = args.directory / "blobs" / "sha256" / config_digest.removeprefix("sha256:")
    if "sha256:" + hashlib.sha256(config.read_bytes()).hexdigest() != config_digest:
        parser.error("config content digest mismatch")
    config_document = json.loads(config.read_text())
    if config_document.get("rootfs") != {"type": "layers", "diff_ids": [args.rootfs_digest]}:
        parser.error("OCI image does not contain the expected single-layer rootfs payload")
    layers = manifest_document.get("layers", [])
    if len(layers) != 1:
        parser.error("OCI image does not contain exactly one rootfs layer")
    layer_digest = layers[0]["digest"]
    layer = args.directory / "blobs" / "sha256" / layer_digest.removeprefix("sha256:")
    if "sha256:" + hashlib.sha256(layer.read_bytes()).hexdigest() != layer_digest:
        parser.error("layer content digest mismatch")
    media_type = layers[0]["mediaType"]
    if media_type == "application/vnd.oci.image.layer.v1.tar":
        stream = layer.open("rb")
    elif media_type == "application/vnd.oci.image.layer.v1.tar+gzip":
        stream = gzip.open(layer, "rb")
    else:
        parser.error("unsupported rootfs layer media type")
    rootfs_hash = hashlib.sha256()
    with stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            rootfs_hash.update(chunk)
    if "sha256:" + rootfs_hash.hexdigest() != args.rootfs_digest:
        parser.error("rootfs layer content does not match the expected payload digest")
index["manifests"] = manifests
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
