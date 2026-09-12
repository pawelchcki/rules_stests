import os
from pathlib import Path
import subprocess
import tarfile
import tempfile
import unittest


class OriginalSnapshotTest(unittest.TestCase):
    def test_rejects_added_source_but_allows_bazel_links(self):
        script = Path(os.environ["TEST_SRCDIR"]) / os.environ["TEST_WORKSPACE"] / "tools/benchmark_datadog.py"
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            checkout = root / "checkout"
            checkout.mkdir()
            subprocess.run(["git", "init", "-q"], cwd=checkout, check=True)
            subprocess.run(["git", "config", "user.name", "Test"], cwd=checkout, check=True)
            subprocess.run(["git", "config", "user.email", "test@example.invalid"], cwd=checkout, check=True)
            source = checkout / "report/report/example.go"
            source.parent.mkdir(parents=True)
            source.write_text("package main\n")
            subprocess.run(["git", "add", "."], cwd=checkout, check=True)
            subprocess.run(["git", "commit", "-qm", "original"], cwd=checkout, check=True)
            revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=checkout, text=True).strip()

            archive = root / "original.tar"
            with archive.open("wb") as stream:
                subprocess.run(["git", "archive", revision], cwd=checkout, stdout=stream, check=True)
            snapshot = root / "snapshot"
            snapshot.mkdir()
            with tarfile.open(archive) as source_archive:
                source_archive.extractall(snapshot)
            output_base = root / "output-base"
            output_base.mkdir()
            (snapshot / "bazel-out").symlink_to(output_base / "execroot/repo/bazel-out")
            (snapshot / ".git").mkdir()
            marker = root / "bazel-calls"
            binary_directory = root / "bin"
            binary_directory.mkdir()
            fake_bazel = binary_directory / "bazel"
            fake_bazel.write_text(
                "#!/usr/bin/env bash\n"
                f"printf 'called\\n' >> {str(marker)!r}\n"
                "exit 77\n"
            )
            fake_bazel.chmod(0o755)
            environment = dict(os.environ)
            environment["PATH"] = str(binary_directory) + os.pathsep + environment["PATH"]

            command = [
                str(script), "--original", str(snapshot),
                "--original-output-base", str(output_base),
                "--original-revision", revision,
                "--output", str(root / "results"),
            ]
            allowed = subprocess.run(
                command, cwd=checkout, text=True, capture_output=True, env=environment
            )
            self.assertNotIn("original snapshot contains untracked path", allowed.stderr)
            self.assertTrue((root / "results").is_dir())
            self.assertEqual(marker.read_text().splitlines(), ["called"])

            added = snapshot / "report/report/extra.go"
            added.write_text("package main\n")
            rejected = subprocess.run(
                command, cwd=checkout, text=True, capture_output=True, env=environment
            )
            self.assertNotEqual(rejected.returncode, 0)
            self.assertIn(
                "original snapshot contains untracked path report/report/extra.go",
                rejected.stderr,
            )
            self.assertEqual(marker.read_text().splitlines(), ["called"])

            added.unlink()
            moved_report = root / "moved-report"
            (snapshot / "report").rename(moved_report)
            (moved_report / "report/extra.go").write_text("package main\n")
            (snapshot / "report").symlink_to(moved_report, target_is_directory=True)
            symlinked = subprocess.run(
                command, cwd=checkout, text=True, capture_output=True, env=environment
            )
            self.assertNotEqual(symlinked.returncode, 0)
            self.assertIn(
                "original snapshot tracked directory is a symlink at report",
                symlinked.stderr,
            )
            self.assertEqual(marker.read_text().splitlines(), ["called"])


if __name__ == "__main__":
    unittest.main()
