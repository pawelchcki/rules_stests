#!/usr/bin/env python3
"""Regression tests for local OCI repository materialization."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


HELPER = Path(__file__).with_name("local_oci_repository.py")


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
