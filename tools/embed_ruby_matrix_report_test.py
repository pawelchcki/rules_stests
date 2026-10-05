import base64
import copy
import gzip
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

from embed_ruby_matrix_report import embed, matrix_result


class MatrixReportTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.runtime = {"series": "4.0", "version": "4.0.7", "image": "ruby@sha256:pin"}
        self.plan = {"runtimes": [self.runtime], "tests": {"4.0": ["//fixtures:ruby_4_0_test"]}, "parityTest": "//fixtures:ruby_matrix_parity_test"}
        self.summary = {"schemaVersion": 1, "runtimes": [self.runtime], "responseCount": 76, "responseSha256": "b" * 64}
        self.archive = Path(self.temporary.name, "outputs.zip")
        self.write_summary()
        self.events = []
        for label in [self.plan["tests"]["4.0"][0], self.plan["parityTest"]]:
            self.events.append({"id": {"testSummary": {"label": label}}, "testSummary": {"overallStatus": "PASSED"}})
            self.events.append({"id": {"testResult": {"label": label}}, "testResult": {"status": "PASSED", "cachedLocally": True, "testActionOutput": [
                {"name": "test.outputs__outputs.zip", "uri": self.archive.as_uri()}
            ] if label == self.plan["parityTest"] else []}})

    def write_summary(self):
        with zipfile.ZipFile(self.archive, "w") as archive:
            archive.writestr("ruby-matrix-parity.json", json.dumps(self.summary))

    def result(self, events=None):
        return matrix_result(self.plan, self.events if events is None else events, "a" * 40, "https://example.test/blob/" + "a" * 40)

    def test_complete_cached_results_and_embedding(self):
        result = self.result()
        self.assertEqual(result["testCount"], 2)
        self.assertTrue(result["versions"][0]["tests"][0]["cached"])
        self.assertTrue(result["parityCached"])
        payload = base64.b64encode(gzip.compress(b'{"manifests":[]}')).decode()
        html = f'<script type="application/octet-stream" id="report-data">{payload}</script>'
        output = embed(html, result)
        data = json.loads(gzip.decompress(base64.b64decode(output.split(">")[1].split("<")[0])))
        self.assertEqual(data["rubyMatrix"], result)
        self.assertEqual(data["manifests"], [])

    def test_missing_failed_and_duplicate_results_are_rejected(self):
        missing = self.events[2:]
        failed = copy.deepcopy(self.events)
        failed[0]["testSummary"]["overallStatus"] = "FAILED"
        duplicate = self.events + [self.events[0]]
        no_execution = [event for event in self.events if event != self.events[1]]
        for events in [missing, failed, duplicate, no_execution]:
            with self.subTest(events=events), self.assertRaises(ValueError):
                self.result(events)

    def test_wrong_runtime_empty_responses_and_invalid_digest_are_rejected(self):
        for key, value in [("runtimes", []), ("responseCount", 0), ("responseCount", True), ("responseSha256", "bad")]:
            with self.subTest(key=key):
                original = self.summary[key]
                self.summary[key] = value
                self.write_summary()
                with self.assertRaises(ValueError):
                    self.result()
                self.summary[key] = original

    def test_remote_or_missing_artifact_is_rejected(self):
        events = copy.deepcopy(self.events)
        events[-1]["testResult"]["testActionOutput"][0]["uri"] = "bytestream://remote/blobs/hash"
        with self.assertRaisesRegex(ValueError, "downloaded locally"):
            self.result(events)
        events[-1]["testResult"]["testActionOutput"] = []
        with self.assertRaisesRegex(ValueError, "exactly one"):
            self.result(events)

    def telemetry_fixture(self):
        self.plan["telemetry"] = {"4.0": {"status": "supported", "profile": "ruby-4", "sdkVersion": "1.13.1"}}
        self.plan["telemetryScenarios"] = ["articles", "propagation"]
        model = {"receipts": [], "captures": []}
        for scenario in self.plan["telemetryScenarios"]:
            proof = {"profile": "ruby-4", "scenario": scenario, "revision": "a" * 40, "outcome": "verified"}
            model["receipts"].append(proof)
            model["captures"].append(dict(proof, spans=[{"name": "GET /api/articles"}]))
        return model

    def embed_model(self, model, result=None):
        payload = base64.b64encode(gzip.compress(json.dumps(model).encode())).decode()
        output = embed(f'<script id="report-data">{payload}</script>', self.result() if result is None else result)
        return json.loads(gzip.decompress(base64.b64decode(output.split(">")[1].split("<")[0])))

    def test_telemetry_requires_every_current_verified_scenario_and_readable_capture(self):
        model = self.telemetry_fixture()
        accepted = self.embed_model(model)
        self.assertEqual(accepted["rubyMatrix"]["versions"][0]["telemetry"]["status"], "verified")
        for collection, field, value in [
            ("receipts", "revision", "b" * 40), ("receipts", "outcome", "xfail"),
            ("captures", "revision", "b" * 40), ("captures", "outcome", "xfail"),
            ("captures", "spans", []), ("captures", "diagnostics", ["invalid topology"]),
        ]:
            with self.subTest(collection=collection, field=field):
                invalid = copy.deepcopy(model)
                invalid[collection][-1][field] = value
                with self.assertRaises(ValueError):
                    self.embed_model(invalid)
        for collection in ["receipts", "captures"]:
            invalid = copy.deepcopy(model)
            invalid[collection].pop()
            with self.subTest(missing=collection), self.assertRaises(ValueError):
                self.embed_model(invalid)
        self.plan["telemetryScenarios"] = []
        with self.assertRaisesRegex(ValueError, "scenario evidence"):
            self.embed_model(model)

    def test_unsupported_runtime_remains_visible_without_capture(self):
        self.plan["telemetry"] = {"4.0": {"status": "unsupported", "reason": "No compatible official exporter"}}
        data = self.embed_model({})
        self.assertEqual(data["rubyMatrix"]["versions"][0]["telemetry"], self.plan["telemetry"]["4.0"])


if __name__ == "__main__":
    unittest.main()
