"""Exercise CI orchestration without requiring a runner or remote executor."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


class CIScriptsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "tools").mkdir()
        (self.root / "bin").mkdir()
        (self.root / "artifacts").mkdir()
        (self.root / "examples/plugin_agent").mkdir(parents=True)
        for name in ["run_ci.sh", "assemble_otel_report.sh"]:
            shutil.copy(Path(__file__).with_name(name), self.root / "tools" / name)
        self.log = self.root / "calls.jsonl"
        self.env = {
            **os.environ,
            "PATH": str(self.root / "bin") + os.pathsep + os.environ["PATH"],
            "CI_TEST_ROOT": str(self.root),
            "REPORT_REVISION": "a" * 40,
            "REPORT_REPOSITORY": "owner/repo",
            "BUILDBUDDY_ARTIFACTS_DIRECTORY": str(self.root / "artifacts"),
        }
        for key in ["BUILD_WORKSPACE_DIRECTORY", "REPORT_RULESET", "REPORT_RULESET_SOURCE_ROOT",
                    "RUBY_MATRIX_BEP", "REPORT_MANIFEST", "REPORT_BAZEL_CONFIG",
                    "OTEL_TEST_REVISION"]:
            self.env.pop(key, None)
        self.executable("bin/bazel", '''
import json, os, pathlib, sys
root = pathlib.Path(os.environ["CI_TEST_ROOT"])
args = sys.argv[1:]
with (root / "calls.jsonl").open("a") as log:
    log.write(json.dumps({"tool": "bazel", "args": args,
                          "revision": os.environ.get("OTEL_TEST_REVISION")}) + "\\n")
if args[0] == "cquery":
    if os.environ.get("CI_QUERY_EXIT"):
        sys.exit(int(os.environ["CI_QUERY_EXIT"]))
    outputs = {"assemble": "bin/assemble", "report_manifest": "manifest.json",
               "report_matrix": "matrix.md", "report_metadata": "metadata.json"}
    if os.environ.get("RUBY_MATRIX_BEP"):
        outputs.update(ruby_matrix_report_plan="ruby-plan.json", embed_ruby_matrix_report="bin/embed")
    outputs.pop(os.environ.get("CI_MISSING_OUTPUT", ""), None)
    for name, path in outputs.items():
        print(name + "\\t" + path)
    if os.environ.get("CI_DUPLICATE_OUTPUT"):
        print("report_manifest\\tother.json")
elif args[0] == "info":
    print(root)
''')
        for tool in ["assemble", "embed"]:
            self.executable("bin/" + tool, '''
import json, os, pathlib, sys
root = pathlib.Path(os.environ["CI_TEST_ROOT"])
with (root / "calls.jsonl").open("a") as log:
    log.write(json.dumps({"tool": pathlib.Path(sys.argv[0]).name, "args": sys.argv[1:]}) + "\\n")
(root / "feature-parity-report.html").write_text("verified report")
''')
        self.executable("bin/git", '''
import sys
if sys.argv[1] == "rev-parse": print("a" * 40)
elif sys.argv[1] == "show": print("author@example.test")
''')

    def executable(self, name, source):
        path = self.root / name
        path.write_text("#!" + sys.executable + "\n" + source)
        path.chmod(0o755)

    def run_script(self, name, *args):
        return subprocess.run(["bash", "tools/" + name, *args], cwd=self.root,
                              env=self.env, text=True, capture_output=True)

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def test_report_assembly_batches_inputs_in_both_modes(self):
        for matrix in [False, True]:
            with self.subTest(matrix=matrix):
                self.log.unlink(missing_ok=True)
                if matrix:
                    self.env["RUBY_MATRIX_BEP"] = "ruby-matrix.bep.json"
                run = self.run_script("assemble_otel_report.sh")
                self.assertEqual(run.returncode, 0, run.stderr)
                calls = self.calls()
                bazel = [c for c in calls if c["tool"] == "bazel"]
                self.assertEqual([c["args"][0] for c in bazel], ["build", "cquery", "info"])
                self.assertEqual("//fixtures:ruby_matrix_report_plan" in bazel[0]["args"], matrix)
                assembled = next(c for c in calls if c["tool"] == "assemble")
                for flag, path in [("manifest", "manifest.json"), ("matrix", "matrix.md"),
                                   ("metadata", "metadata.json")]:
                    self.assertIn(f"--{flag}={self.root / path}", assembled["args"])
                self.assertEqual(any(c["tool"] == "embed" for c in calls), matrix)

    def test_query_failure_or_incomplete_outputs_stop_assembly(self):
        for key, value in [("CI_QUERY_EXIT", "7"), ("CI_MISSING_OUTPUT", "report_matrix"),
                           ("CI_DUPLICATE_OUTPUT", "1")]:
            with self.subTest(failure=key):
                self.log.unlink(missing_ok=True)
                self.env[key] = value
                run = self.run_script("assemble_otel_report.sh")
                self.assertNotEqual(run.returncode, 0)
                self.assertFalse(any(c["tool"] == "assemble" for c in self.calls()))
                self.env.pop(key)

    def test_consumer_labels_and_config_are_preserved(self):
        self.env.update(REPORT_RULESET="@rules_stests", REPORT_MANIFEST="//:consumer_manifest",
                        REPORT_RULESET_SOURCE_ROOT="https://example.test/blob/" + "b" * 40,
                        REPORT_BAZEL_CONFIG="local")
        run = self.run_script("assemble_otel_report.sh")
        self.assertEqual(run.returncode, 0, run.stderr)
        calls = self.calls()
        self.assertIn("@rules_stests//report:assemble", calls[0]["args"])
        self.assertIn("//:consumer_manifest", calls[0]["args"])
        self.assertTrue(all("--config=local" in c["args"] for c in calls if c["tool"] == "bazel"))
        self.assertIn("--corpus-source-root=" + self.env["REPORT_RULESET_SOURCE_ROOT"],
                      calls[-1]["args"])

    def test_ci_preserves_cache_and_fresh_evidence_with_selective_downloads(self):
        for mode in ["pr", "full"]:
            with self.subTest(mode=mode):
                self.log.unlink(missing_ok=True)
                run = self.run_script("run_ci.sh", mode)
                self.assertEqual(run.returncode, 0, run.stderr)
                tests = [c for c in self.calls() if c["tool"] == "bazel" and c["args"][0] == "test"]
                api, telemetry, example = tests
                self.assertNotIn("--nocache_test_results", api["args"])
                self.assertIsNone(api["revision"])
                self.assertIn("--nocache_test_results", telemetry["args"])
                self.assertEqual(telemetry["revision"], "a" * 40)
                self.assertIn("--test_env=OTEL_TEST_REVISION", telemetry["args"])
                for call in [api, telemetry]:
                    self.assertNotIn("--spawn_strategy=remote,local", call["args"])
                    self.assertIn("--remote_download_outputs=minimal", call["args"])
                    self.assertIn(r"--remote_download_regex=.*/test\.outputs(/.*)?", call["args"])
                self.assertEqual((self.root / "artifacts/opentelemetry-proof-report.html").read_text(),
                                 "verified report")


if __name__ == "__main__":
    unittest.main()
