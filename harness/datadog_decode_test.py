"""Exercise repeated metadata through the production native intake decoder."""
import json
from pathlib import Path
import re
import socket
import subprocess
import sys
import tempfile
import time
import unittest
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


def text(value):
    body = value.encode()
    assert len(body) < 32
    return bytes([0xa0 + len(body)]) + body


def pairs(entries):
    assert len(entries) < 16
    return bytes([0x80 + len(entries)]) + b"".join(text(key) + value for key, value in entries)


def binary(value):
    return b"\xc6" + len(value).to_bytes(4, "big") + value


def completed_span(extra, span_id=b"\x02"):
    return pairs([("trace_id", b"\x01"), ("span_id", span_id),
                  ("service", text("security")), ("name", text("request")),
                  ("resource", text("GET /")), ("start", b"\x01"),
                  ("duration", b"\x01")] + extra)


class DecodeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        with socket.socket() as reserved:
            reserved.bind(("127.0.0.1", 0))
            port = reserved.getsockname()[1]
        cls.url = "http://127.0.0.1:" + str(port)
        cls.log = open(Path(cls.directory.name) / "sink.log", "wb")
        cls.process = subprocess.Popen([sys.argv[1], "--port", str(port), "--output", str(Path(cls.directory.name) / "capture.json")], stdout=cls.log, stderr=cls.log)
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            if cls.process.poll() is not None:
                raise AssertionError("sink exited before readiness")
            try:
                with urlopen(cls.url + "/healthz", timeout=1):
                    return
            except URLError:
                time.sleep(0.05)
        raise AssertionError("sink readiness timeout")

    @classmethod
    def tearDownClass(cls):
        cls.process.terminate()
        try:
            cls.process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            cls.process.kill()
            cls.process.wait()
        cls.log.close()
        cls.directory.cleanup()

    def request(self, path, body=None, content_type="application/msgpack", expected=200):
        request = Request(self.url + path, data=body, headers={"Content-Type": content_type})
        try:
            response = urlopen(request, timeout=5)
        except HTTPError as error:
            response = error
        with response:
            self.assertEqual(response.status, expected)
            return response.read()

    def assert_semantic_validity(self, valid, span_count=1):
        self.assert_semantic_flags(["#t" if valid else "#f"] * (1 + span_count))

    def assert_semantic_flags(self, expected):
        layout = self.request("/dump.scm?protocol=datadog").decode()
        flags = re.findall(r"\(semantic-valid (#[tf])\)", layout)
        # The first flag describes scenario-level trace shapes. Check the
        # request and each span independently of those workload requirements.
        self.assertEqual(flags[1:], expected, layout)

    def test_identical_propagation_metadata_is_coalesced(self):
        self.request("/reset?protocol=datadog", b"")
        # Only the metadata values are repeated. The enclosing wire layout is
        # [[span]], where the production decoder recognizes a span.meta map.
        span = pairs([("trace_id", b"\x01"), ("span_id", b"\x02"),
                      ("meta", pairs([("_dd.origin", text("synthetics")), ("_dd.origin", text("synthetics"))]))])
        self.request("/v0.4/traces", b"\x91\x91" + span)
        capture = json.loads(self.request("/dump?protocol=datadog"))
        self.assertEqual(capture[0]["payload"]["traces"][0][0]["meta"], {"_dd.origin": "synthetics"})

    def test_conflicting_metadata_and_structural_duplicates_fail(self):
        for span in [
            pairs([("meta", pairs([("_dd.origin", text("one")), ("_dd.origin", text("two"))]))]),
            pairs([("span_id", b"\x02"), ("span_id", b"\x02")]),
            pairs([("metrics", pairs([("number", b"\x01"), ("number", b"\x01")]))]),
            pairs([("meta", pairs([("number", b"\x01"), ("number", b"\x01")]))]),
            pairs([("meta", pairs([("nested", pairs([("x", text("one")), ("x", text("one"))]))]))]),
        ]:
            with self.subTest(span=span):
                self.request("/v0.4/traces", b"\x91\x91" + span, expected=400)

    def test_duplicate_json_metadata_remains_rejected(self):
        self.request("/v0.4/traces", b'[[{"meta":{"x":"one","x":"one"}}]]', "application/json", expected=400)

    def test_security_reports_are_negotiated_and_binary_is_retained(self):
        self.assertTrue(json.loads(self.request("/info"))["span_meta_structs"])
        self.request("/reset?protocol=datadog", b"")
        report = pairs([("vulnerabilities", b"\x90")])
        span = pairs([("trace_id", b"\x01"), ("span_id", b"\x02"),
                      ("service", text("security")), ("name", text("request")),
                      ("resource", text("GET /")), ("start", b"\x01"), ("duration", b"\x01"),
                      ("meta_struct", pairs([("iast", b"\xc4" + bytes([len(report)]) + report)]))])
        self.request("/v0.4/traces", b"\x91\x91" + span)
        capture = json.loads(self.request("/dump?protocol=datadog"))
        self.assertEqual(capture[0]["payload"]["traces"][0][0]["meta_struct"], {"iast": list(report)})
        self.assert_semantic_validity(True)

    def test_security_binary_is_still_bounded(self):
        # A declared bin32 value must not allocate or read beyond the decoder's
        # shared budget, even when the network request itself is tiny.
        span = pairs([("meta_struct", pairs([("iast", b"\xc6\xff\xff\xff\xff")]))])
        self.request("/v0.4/traces", b"\x91\x91" + span, expected=400)

    def test_large_security_report_uses_byte_budget(self):
        self.request("/reset?protocol=datadog", b"")
        report = b"\x00" * (70 * 1024)
        span = completed_span([("meta_struct", pairs([("iast", binary(report))]))])
        self.request("/v0.4/traces", b"\x91\x91" + span)
        capture = json.loads(self.request("/dump?protocol=datadog"))
        self.assertEqual(capture[0]["payload"]["traces"][0][0]["meta_struct"], {"iast": list(report)})
        self.assert_semantic_validity(True)

    def test_native_array_is_not_a_binary_security_report(self):
        for encoded in (b"\x92\x01\x02", b"\x90"):
            with self.subTest(encoded=encoded):
                self.request("/reset?protocol=datadog", b"")
                span = completed_span([("meta_struct", pairs([("iast", encoded)]))])
                self.request("/v0.4/traces", b"\x91\x91" + span)
                self.assert_semantic_validity(False)

    def test_empty_binary_report_preserves_type(self):
        for encoded in (b"\xc4\x00", b"\xc5\x00\x00", binary(b"")):
            with self.subTest(encoded=encoded):
                self.request("/reset?protocol=datadog", b"")
                span = completed_span([("meta_struct", pairs([("iast", encoded)]))])
                self.request("/v0.4/traces", b"\x91\x91" + span)
                capture = json.loads(self.request("/dump?protocol=datadog"))
                self.assertEqual(capture[0]["payload"]["traces"][0][0]["meta_struct"], {"iast": []})
                self.assert_semantic_validity(True)

    def test_arrays_still_consume_the_structural_node_budget(self):
        self.request("/reset?protocol=datadog", b"")
        self.request("/v0.4/traces", b"\xdd\x00\x01\x00\x00" + b"\x00" * 65536, expected=400)
        self.assertEqual(json.loads(self.request("/dump?protocol=datadog")), [])

    def test_json_array_has_no_native_binary_provenance(self):
        self.request("/reset?protocol=datadog", b"")
        span = {"trace_id": 1, "span_id": 2, "service": "security", "name": "request",
                "resource": "GET /", "start": 1, "duration": 1, "meta_struct": {"iast": [1, 2]}}
        self.request("/v0.4/traces", json.dumps([[span]]).encode(), "application/json")
        self.assert_semantic_validity(False)

    def test_binary_proof_is_scoped_to_its_span(self):
        self.request("/reset?protocol=datadog", b"")
        native = completed_span([("meta_struct", pairs([("iast", binary(b"\x01\x02"))]))])
        array = completed_span([("meta_struct", pairs([("iast", b"\x92\x01\x02")]))], b"\x03")
        self.request("/v0.4/traces", b"\x91\x92" + native + array)
        self.assert_semantic_flags(["#f", "#t", "#f"])

    def test_binary_proof_is_scoped_to_its_request(self):
        self.request("/reset?protocol=datadog", b"")
        for encoded in (binary(b"\x01\x02"), b"\x92\x01\x02"):
            span = completed_span([("meta_struct", pairs([("iast", encoded)]))])
            self.request("/v0.4/traces", b"\x91\x91" + span)
        self.assert_semantic_flags(["#t", "#f", "#t", "#f"])

    def test_invalid_trace_container_does_not_invalidate_unrelated_spans(self):
        for extra in ([], [("meta_struct", pairs([("iast", binary(b"\x01\x02"))]))]):
            with self.subTest(extra=extra):
                self.request("/reset?protocol=datadog", b"")
                self.request("/v0.4/traces", b"\x92" + binary(b"") + b"\x91" + completed_span(extra))
                self.assert_semantic_flags(["#f", "#t"])

    def test_binary_cannot_impersonate_an_empty_array(self):
        for path, body in [
            ("/v0.4/traces", binary(b"")),
            ("/v0.4/traces", b"\x91\x91" + completed_span([("span_links", binary(b""))])),
            ("/v0.5/traces", b"\x92" + binary(b"") + b"\x90"),
        ]:
            with self.subTest(path=path, body=body):
                self.request("/reset?protocol=datadog", b"")
                self.request(path, body)
                self.assert_semantic_validity(False, span_count=1 if b"span_links" in body else 0)

    def test_binary_backing_allocation_is_bounded(self):
        # These two blobs fit the wire limit, but their expanded JSON arrays
        # exceed the ordinary sink's four-MiB retained allocation ceiling.
        report = b"\x00" * (100 * 1024)
        span = completed_span([("meta_struct", pairs([("iast", binary(report)), ("appsec", binary(report))]))])
        self.request("/reset?protocol=datadog", b"")
        self.request("/v0.4/traces", b"\x91\x91" + span, expected=400)
        self.assertEqual(json.loads(self.request("/dump?protocol=datadog")), [])


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]])
