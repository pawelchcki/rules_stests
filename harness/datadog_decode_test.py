"""Exercise repeated metadata through the production native intake decoder."""
import json
from pathlib import Path
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
        self.assertIn(b"(semantic-valid #t)", self.request("/dump.scm?protocol=datadog"))

    def test_security_binary_is_still_bounded(self):
        # A declared bin32 value must not allocate or read beyond the decoder's
        # shared budget, even when the network request itself is tiny.
        span = pairs([("meta_struct", pairs([("iast", b"\xc6\xff\xff\xff\xff")]))])
        self.request("/v0.4/traces", b"\x91\x91" + span, expected=400)


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]])
