import unittest

from verify_native_ruby_receipts import flatten_spans, has_ancestor, span_key


class TraceIdentityTest(unittest.TestCase):
    def test_parent_lookup_stays_within_128_bit_trace(self):
        records = [{"payload": {"traces": [
            [{"trace_id": 7, "span_id": 2, "parent_id": 0,
              "meta": {"_dd.p.tid": "aaaaaaaaaaaaaaaa"}}],
            [{"trace_id": 7, "span_id": 2, "parent_id": 0,
              "meta": {"_dd.p.tid": "bbbbbbbbbbbbbbbb"}},
             {"trace_id": 7, "span_id": 3, "parent_id": 2, "meta": {}}],
        ]}}]
        first, second, child = flatten_spans(records)
        self.assertNotEqual(span_key(first), span_key(second))
        self.assertTrue(has_ancestor(child, [first, second, child],
                                     lambda parent: parent is second))
        self.assertFalse(has_ancestor(child, [first, second, child],
                                      lambda parent: parent is first))

    def test_untagged_chunk_does_not_borrow_another_traces_high_bits(self):
        records = [{"payload": {"traces": [
            [{"trace_id": 7, "span_id": 2, "parent_id": 0,
              "meta": {"_dd.p.tid": "aaaaaaaaaaaaaaaa"}}],
            [{"trace_id": 7, "span_id": 3, "parent_id": 2, "meta": {}}],
        ]}}]
        parent, child = flatten_spans(records)
        self.assertFalse(has_ancestor(child, [parent, child], lambda _: True))


if __name__ == "__main__":
    unittest.main()
