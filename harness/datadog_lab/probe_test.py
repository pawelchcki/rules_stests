import copy
import sys
from pathlib import Path
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parent))

from probe import assert_carrier, assert_graph, decoded_spans

IDENTITY = {
    "trace_id": str(0x1234567890abcdef00000000075bcd15),
    "root_id": "987654321", "root_parent_id": "0",
    "child_id": "42", "child_parent_id": "987654321",
    "service": "lab-service", "name": "lab.request", "priority": -1,
}
ROOT = {"trace_id": 123456789, "span_id": 987654321, "parent_id": 0,
        "name": "lab.request", "service": "lab-service",
        "meta": {"_dd.p.tid": "1234567890abcdef"},
        "metrics": {"_sampling_priority_v1": -1, "_dd.span_sampling.rule_rate": 1.0, "_dd.span_sampling.mechanism": 8}, "start": 1, "duration": 1}
CHILD = {"trace_id": 123456789, "span_id": 42, "parent_id": 987654321,
         "name": "lab.child", "service": "lab-child", "meta": {}, "metrics": {}, "start": 1, "duration": 1}
CASE = {"expected": 1, "rules": [{}]}


class ProbeChecks(unittest.TestCase):
    def test_graph_accepts_exact_identity_and_rejects_mutations(self):
        assert_graph([ROOT, CHILD], IDENTITY, CASE)
        for span_index, field, wrong in [
            (0, "trace_id", 99), (0, "span_id", 99), (1, "parent_id", 99),
            (1, "trace_id", 99), (1, "span_id", 99),
        ]:
            spans = copy.deepcopy([ROOT, CHILD])
            spans[span_index][field] = wrong
            with self.subTest(span_index=span_index, field=field), self.assertRaises((AssertionError, KeyError)):
                assert_graph(spans, IDENTITY, CASE)
        with self.assertRaises(AssertionError):
            assert_graph([ROOT], IDENTITY, CASE)
        with self.assertRaises(AssertionError):
            assert_graph([ROOT, CHILD, CHILD], IDENTITY, CASE)
        wrong = copy.deepcopy(IDENTITY)
        wrong["priority"] = 2
        with self.assertRaises(AssertionError):
            assert_graph([ROOT, CHILD], wrong, CASE)
        wrong = copy.deepcopy([ROOT, CHILD])
        wrong[0]["meta"]["_dd.p.tid"] = "ffffffffffffffff"
        with self.assertRaises(AssertionError):
            assert_graph(wrong, IDENTITY, CASE)

    def test_sampling_markers_must_be_on_matching_root_only(self):
        for mutation in [
            lambda spans: spans[0]["metrics"].pop("_dd.span_sampling.rule_rate"),
            lambda spans: spans[0]["metrics"].__setitem__("_dd.span_sampling.mechanism", 9),
            lambda spans: spans[1]["metrics"].__setitem__("_dd.span_sampling.rule_rate", 1),
            lambda spans: spans[0]["metrics"].__setitem__("_dd.span_sampling.max_per_second", 20),
        ]:
            spans = copy.deepcopy([ROOT, CHILD])
            mutation(spans)
            with self.assertRaises(AssertionError):
                assert_graph(spans, IDENTITY, CASE)
        no_markers = copy.deepcopy([ROOT, CHILD])
        no_markers[0]["metrics"] = {"_sampling_priority_v1": -1}
        assert_graph(no_markers, IDENTITY, {"expected": None, "rules": [{}]})
        with self.assertRaises(AssertionError):
            assert_graph([ROOT, CHILD], IDENTITY, {"expected": None, "rules": [{}]})


    def test_each_injection_format_checks_full_identity_and_sampled_state(self):
        full = "1234567890abcdef00000000075bcd15"
        root = "000000003ade68b1"
        carriers = {
            "tracecontext": {"traceparent": f"00-{full}-{root}-00", "tracestate": f"dd=s:-1;p:{root}"},
            "b3": {"b3": f"{full}-{root}-0"},
            "b3multi": {"x-b3-traceid": full, "x-b3-spanid": root, "x-b3-sampled": "0"},
        }
        for style, carrier in carriers.items():
            with self.subTest(style=style):
                assert_carrier(carrier, [style], IDENTITY)
                bad = copy.deepcopy(carrier)
                key = {"tracecontext": "traceparent", "b3": "b3", "b3multi": "x-b3-traceid"}[style]
                bad[key] = bad[key].replace(full, "ffffffffffffffffffffffffffffffff")
                with self.assertRaises(AssertionError):
                    assert_carrier(bad, [style], IDENTITY)
                bad = copy.deepcopy(carrier)
                key = {"tracecontext": "traceparent", "b3": "b3", "b3multi": "x-b3-sampled"}[style]
                if style == "b3multi":
                    bad[key] = "1"
                elif style == "tracecontext":
                    bad[key] = bad[key][:-2] + "01"
                else:
                    bad[key] = bad[key][:-1] + "1"
                with self.assertRaises(AssertionError):
                    assert_carrier(bad, [style], IDENTITY)
        debug = copy.deepcopy(IDENTITY)
        debug["priority"] = 2
        assert_carrier({"b3": f"{full}-{root}-d"}, ["b3"], debug)
        assert_carrier({"x-b3-traceid": full, "x-b3-spanid": root, "x-b3-flags": "1"}, ["b3multi"], debug)
        with self.assertRaises(AssertionError):
            assert_carrier({"b3": f"{full}-{root}-1"}, ["b3"], debug)
        with self.assertRaises(AssertionError):
            assert_carrier({"x-b3-traceid": full, "x-b3-spanid": root, "x-b3-sampled": "1"}, ["b3multi"], debug)
        mixed = {"x-datadog-trace-id": "123456789", "x-datadog-parent-id": "987654321",
                 "x-datadog-sampling-priority": "-1", "x-datadog-tags": "_dd.p.tid=1234567890abcdef"}
        mixed.update(carriers["tracecontext"])
        mixed.update(carriers["b3"])
        mixed.update(carriers["b3multi"])
        assert_carrier(mixed, list(carriers) + ["datadog"], IDENTITY)
        with self.assertRaises(AssertionError):
            assert_carrier(mixed, [], IDENTITY)
        assert_carrier({}, [], IDENTITY)
        wrong = copy.deepcopy(IDENTITY)
        wrong["trace_id"] = str(123456789)
        with self.assertRaises(AssertionError):
            assert_carrier({}, [], wrong)


    def test_datadog_tags_require_exact_unique_trace_id_field(self):
        good = {"x-datadog-trace-id": "123456789", "x-datadog-parent-id": "987654321",
                "x-datadog-sampling-priority": "-1", "x-datadog-tags": "_dd.p.dm=-3,_dd.p.tid=1234567890abcdef"}
        assert_carrier(good, ["datadog"], IDENTITY)
        for tags in [
            "_dd.p.tid=1234567890abcdefjunk",
            "other=_dd.p.tid=1234567890abcdef",
            "x_dd.p.tid=1234567890abcdef",
            "_dd.p.tid=1234567890abcdef,_dd.p.tid=ffffffffffffffff",
            "_dd.p.dm=-3,_dd.p.dm=-4,_dd.p.tid=1234567890abcdef",
            "_dd.p.tid=1234567890abcdef,",
        ]:
            with self.subTest(tags=tags), self.assertRaises(AssertionError):
                assert_carrier({**good, "x-datadog-tags": tags}, ["datadog"], IDENTITY)

    def test_tracestate_requires_exact_unique_dd_fields(self):
        root = "000000003ade68b1"
        good = {"traceparent": "00-1234567890abcdef00000000075bcd15-" + root + "-00",
                "tracestate": "vendor=one,dd=p:" + root + ";s:-1;t.dm:-3"}
        assert_carrier(good, ["tracecontext"], IDENTITY)
        for state in [
            "vendor=p:" + root + ";s:-1",
            "dd=p:" + root + "junk;s:-1",
            "dd=xp:" + root + ";s:-1",
            "dd=p:" + root + ";s:0",
            "dd=p:" + root + ";s:-1;p:ffffffffffffffff",
            "dd=p:" + root + ";s:-1,dd=p:ffffffffffffffff;s:-1",
            "dd=p:" + root + ";s:-1;t.dm:-3;t.dm:-4",
            "dd=p:" + root + ";s:-1,",
        ]:
            with self.subTest(state=state), self.assertRaises((AssertionError, KeyError)):
                assert_carrier({**good, "tracestate": state}, ["tracecontext"], IDENTITY)

    def test_native_high_bits_and_timing_are_required(self):
        for field, bad_value in [("_dd.p.tid", "ffffffffffffffff"), ("_dd.p.tid", ""),
                                 ("_dd.p.tid", None)]:
            spans = copy.deepcopy([ROOT, CHILD])
            spans[0]["meta"][field] = bad_value
            with self.assertRaises(AssertionError):
                assert_graph(spans, IDENTITY, CASE)
        for field, bad_value in [("start", 0), ("duration", 0)]:
            spans = copy.deepcopy([ROOT, CHILD])
            spans[1][field] = bad_value
            with self.assertRaises(AssertionError):
                assert_graph(spans, IDENTITY, CASE)

    def test_capture_requires_expected_wire_and_nonempty_chunks(self):
        import json
        good = json.dumps([{"payload": {"wire_version": "v0.4", "traces": [[ROOT, CHILD]]}}]).encode()
        self.assertEqual(len(decoded_spans(good, "v0.4")), 2)
        with self.assertRaises(AssertionError):
            decoded_spans(good, "v0.5")
        with self.assertRaises(AssertionError):
            decoded_spans(json.dumps([{"payload": {"wire_version": "v0.4", "traces": [[]]}}]).encode(), "v0.4")

    def test_carrier_requires_identity_and_selected_formats(self):
        good = {"x-datadog-trace-id": "123456789", "x-datadog-parent-id": "987654321",
                "x-datadog-tags": "_dd.p.tid=1234567890abcdef", "x-datadog-sampling-priority": "-1"}
        assert_carrier(good, ["datadog"], IDENTITY)
        for mutation in [
            {**good, "x-datadog-parent-id": "99"},
            {**good, "x-datadog-trace-id": "99"},
            {**good, "traceparent": "00-1234567890abcdef00000000075bcd15-000000003ade68b1-01"},
            {"x-datadog-parent-id": "987654321"},
        ]:
            with self.assertRaises((AssertionError, KeyError)):
                assert_carrier(mutation, ["datadog"], IDENTITY)
        with self.assertRaises(AssertionError):
            assert_carrier(good, [], IDENTITY)


if __name__ == "__main__":
    unittest.main()
