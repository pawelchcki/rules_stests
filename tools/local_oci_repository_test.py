#!/usr/bin/env python3
"""Regression tests for local OCI repository materialization."""
import gzip
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


HELPER = Path(__file__).with_name("local_oci_repository.py")
FIXTURE_BUILDER = Path(__file__).with_name("build_datadog_fixtures.sh")


def digest(data):
    return "sha256:" + hashlib.sha256(data).hexdigest()


def write_layout(directory, descriptors):
    (directory / "blobs" / "sha256").mkdir(parents=True, exist_ok=True)
    (directory / "oci-layout").write_text('{"imageLayoutVersion":"1.0.0"}')
    (directory / "index.json").write_text(json.dumps({"schemaVersion": 2, "manifests": descriptors}))


def add_manifest(directory, data=b"manifest"):
    value = digest(data)
    (directory / "blobs" / "sha256" / value.removeprefix("sha256:")).write_bytes(data)
    return {"mediaType": "application/vnd.oci.image.manifest.v1+json", "digest": value, "size": len(data)}


def add_image_manifest(directory, layer_data, claimed_rootfs_digest=None, gzip_mtime=None):
    rootfs_digest = claimed_rootfs_digest or digest(layer_data)
    config = json.dumps({
        "created": "1970-01-01T00:00:00Z",
        "rootfs": {"type": "layers", "diff_ids": [rootfs_digest]},
    }).encode()
    config_descriptor = add_manifest(directory, config)
    layer_blob = gzip.compress(layer_data, mtime=gzip_mtime) if gzip_mtime is not None else layer_data
    layer_descriptor = add_manifest(directory, layer_blob)
    layer_descriptor["mediaType"] = (
        "application/vnd.oci.image.layer.v1.tar+gzip"
        if gzip_mtime is not None
        else "application/vnd.oci.image.layer.v1.tar"
    )
    manifest = json.dumps({"config": config_descriptor, "layers": [layer_descriptor]}).encode()
    return add_manifest(directory, manifest)


class LocalOCIRepositoryTest(unittest.TestCase):
    def run_helper(self, directory, *args):
        return subprocess.run(
            [sys.executable, HELPER, directory, "local_fixture", *args],
            capture_output=True,
            check=False,
            text=True,
        )

    def test_single_export_does_not_require_a_recorded_digest(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_layout(directory, [])
            descriptor = add_manifest(directory)
            write_layout(directory, [descriptor])

            result = self.run_helper(directory)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("--override_repository=local_fixture=", result.stdout)
            self.assertEqual(json.loads((directory / "index.json").read_text())["manifests"], [descriptor])

    def test_accepts_repacked_reviewed_rootfs_payload(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            rootfs = b"reviewed rootfs"
            write_layout(directory, [])
            descriptor = add_image_manifest(directory, rootfs, gzip_mtime=123)
            write_layout(directory, [descriptor])

            result = self.run_helper(directory, "--rootfs-digest", digest(rootfs))

            self.assertEqual(result.returncode, 0, result.stderr)

    def test_fixture_builder_surfaces_container_build_failure(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            container_tool = directory / "container-tool"
            container_tool.write_text("#!/usr/bin/env bash\nprintf 'nested container build unavailable: %s\\n' \"$*\" >&2\nexit 125\n")
            container_tool.chmod(0o755)

            result = subprocess.run(
                [FIXTURE_BUILDER, directory / "output"],
                capture_output=True,
                check=False,
                env={
                    **os.environ,
                    "CONTAINER_BUILD_NETWORK": "host",
                    "CONTAINER_TOOL": str(container_tool),
                },
                text=True,
            )

            self.assertEqual(result.returncode, 125)
            self.assertIn("nested container build unavailable", result.stderr)
            self.assertIn("--network host", result.stderr)
            self.assertIn("--network host", (directory / "output" / "ruby.build.log").read_text())

    def test_rejects_corrupted_manifest_blob(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_layout(directory, [])
            descriptor = add_manifest(directory)
            write_layout(directory, [descriptor])
            (directory / "blobs" / "sha256" / descriptor["digest"].removeprefix("sha256:")).write_bytes(b"corrupted")

            result = self.run_helper(directory)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("manifest content digest mismatch", result.stderr)

    def test_rejects_ambiguous_index(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_layout(directory, [])
            first = add_manifest(directory, b"first")
            second = add_manifest(directory, b"second")
            write_layout(directory, [first, second])

            result = self.run_helper(directory)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("OCI index does not contain exactly one manifest", result.stderr)

    def test_requires_reviewed_rootfs_payload(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            rootfs = b"reviewed rootfs"
            rootfs_digest = digest(rootfs)
            write_layout(directory, [])
            descriptor = add_image_manifest(directory, rootfs)
            write_layout(directory, [descriptor])

            result = self.run_helper(directory, "--rootfs-digest", rootfs_digest)

            self.assertEqual(result.returncode, 0, result.stderr)

    def test_rejects_different_rootfs_payload(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            rootfs_digest = digest(b"reviewed rootfs")
            write_layout(directory, [])
            descriptor = add_image_manifest(
                directory,
                b"different rootfs",
                claimed_rootfs_digest=rootfs_digest,
            )
            write_layout(directory, [descriptor])

            result = self.run_helper(directory, "--rootfs-digest", rootfs_digest)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("rootfs layer content does not match", result.stderr)

    def test_rejects_different_config_rootfs_identity(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            rootfs = b"reviewed rootfs"
            write_layout(directory, [])
            descriptor = add_image_manifest(
                directory,
                rootfs,
                claimed_rootfs_digest=digest(b"different rootfs"),
            )
            write_layout(directory, [descriptor])

            result = self.run_helper(directory, "--rootfs-digest", digest(rootfs))

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("expected single-layer rootfs payload", result.stderr)

    def test_digest_option_selects_an_exact_retained_manifest(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_layout(directory, [])
            first = add_manifest(directory, b"first")
            second = add_manifest(directory, b"second")
            write_layout(directory, [first, second])

            result = self.run_helper(directory, "--digest", second["digest"])

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads((directory / "index.json").read_text())["manifests"], [second])


if __name__ == "__main__":
    unittest.main()
