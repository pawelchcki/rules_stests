import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

import datadog_report


GATE = Path(sys.argv.pop(1)).resolve()
REVISION = "a" * 40


def sha(data):
    return hashlib.sha256(data).hexdigest()


def fixture(directory):
    profile, scenario = "ruby-test", "tags"
    proof = {"featureId": "http.server", "assertion": "<script>alert(1)</script>", "basis": "contract"}
    plan = json.dumps({"proofs": [proof]})
    capture, bytecode, shape = b"[]", b"compiled validator", "reviewed shape"
    artifact = {"path": "ruby-test.validators/tags.bin", "sourceSha256": "b" * 64,
                "compilerSha256": "c" * 64, "bytecodeSha256": sha(bytecode)}
    manifest = {"profile": profile, "application": "rails", "family": "datadog", "wireVersion": "v0.4",
                "proofPlan": plan, "scenarios": [scenario], "scenarioShapes": {scenario: shape},
                "compiledValidators": {scenario: artifact}, "validationPolicySha256": "d" * 64,
                "candidateImplementationSha256": "e" * 64}
    receipt = {"profile": profile, "scenario": scenario, "family": "datadog", "wireVersion": "v0.4",
               "schemaVersion": 2, "revision": REVISION, "validationMode": "exact", "outcome": "verified",
               "proofPlanSha256": sha(plan.encode()), "captureSha256": sha(capture),
               "scenarioShapeSha256": sha(shape.encode()), "validationPolicySha256": "d" * 64,
               "candidateImplementationSha256": "e" * 64, "validator": artifact,
               "proofs": [{**proof, "result": "pass"}],
               "coverage": {"schemaVersion": 1, "application": "rails", "scenario": scenario,
                            "integrationSpans": {"http.server": 1, "database": 1}, "spanOccurrences": 2,
                            "fieldPolicies": {"exact": 2, "normalized": 1, "runtime-validated": 1},
                            "fieldOccurrences": 4, "unclassifiedFields": 0}}
    directory.mkdir()
    (directory / "ruby-test.profile.json").write_text(json.dumps(manifest))
    artifact_path = directory / artifact["path"]
    artifact_path.parent.mkdir()
    artifact_path.write_bytes(bytecode)
    receipt_path = directory / profile / scenario / "datadog/receipts" / profile / f"{scenario}.json"
    receipt_path.parent.mkdir(parents=True)
    receipt_path.write_text(json.dumps(receipt))
    receipt_path.with_name("tags.capture.json").write_bytes(capture)
    return receipt_path, artifact_path


class ReportTest(unittest.TestCase):
    def test_two_executions_render_distinct_counts_and_escape_content(self):
        with tempfile.TemporaryDirectory() as root:
            paths = [Path(root) / name for name in ["first", "second"]]
            for path in paths:
                fixture(path)
            report = datadog_report.build_report(paths, REVISION, GATE)
            rendered = datadog_report.render(report)
            self.assertIn("1 distinct scenarios verified across 1 profiles", rendered)
            self.assertIn("in 2 retained executions", rendered)
            self.assertNotIn("<script>alert(1)</script>", rendered)
            self.assertIn("&lt;script&gt;alert(1)&lt;/script&gt;", rendered)

    def test_gate_rejects_mutated_evidence(self):
        for mutation in ["revision", "capture", "bytecode", "proof", "xfail", "coverage"]:
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as root:
                path = Path(root) / "execution"
                receipt_path, artifact_path = fixture(path)
                receipt = json.loads(receipt_path.read_text())
                if mutation == "revision":
                    receipt["revision"] = "f" * 40
                elif mutation == "capture":
                    receipt_path.with_name("tags.capture.json").write_text("[{}]")
                elif mutation == "bytecode":
                    artifact_path.write_bytes(b"changed bytecode")
                elif mutation == "proof":
                    receipt["proofs"] = []
                elif mutation == "xfail":
                    receipt["outcome"] = "xfail"
                elif mutation == "coverage":
                    receipt["coverage"]["unclassifiedFields"] = 1
                receipt_path.write_text(json.dumps(receipt))
                with self.assertRaises(subprocess.CalledProcessError):
                    datadog_report.build_report([path], REVISION, GATE)

    def test_empty_missing_and_repeated_evidence_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root) / "execution"
            receipt, _ = fixture(path)
            with self.assertRaises(ValueError):
                datadog_report.build_report([path, path], REVISION, GATE)
            receipt.unlink()
            with self.assertRaises(FileNotFoundError):
                datadog_report.build_report([path], REVISION, GATE)
            with self.assertRaises(ValueError):
                datadog_report.build_report([Path(root) / "missing"], REVISION, GATE)

    def test_different_execution_coverage_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            paths = [Path(root) / name for name in ["first", "second"]]
            for path in paths:
                fixture(path)
            report = datadog_report.read_execution(paths[1], REVISION, GATE)
            changed = copy.deepcopy(report)
            changed[0]["scenarios"][0]["scenario"] = "other"
            from unittest.mock import patch
            with patch.object(datadog_report, "read_execution", side_effect=[report, changed]):
                with self.assertRaisesRegex(ValueError, "different scenario/profile coverage"):
                    datadog_report.build_report(paths, REVISION, GATE)

    def test_different_execution_contracts_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            paths = [Path(root) / name for name in ["first", "second"]]
            for path in paths:
                fixture(path)
            manifest = paths[1] / "ruby-test.profile.json"
            # Even an otherwise valid manifest must be identical between runs.
            value = json.loads(manifest.read_text())
            value["description"] = "different trusted build input"
            manifest.write_text(json.dumps(value))
            with self.assertRaisesRegex(ValueError, "different profile contracts"):
                datadog_report.build_report(paths, REVISION, GATE)


if __name__ == "__main__":
    unittest.main()
