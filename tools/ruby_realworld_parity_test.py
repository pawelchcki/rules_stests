import copy
import unittest

from ruby_realworld_parity import compare


class ParityTest(unittest.TestCase):
    def setUp(self):
        self.matrix = {"runtimes": [{"series": "1.9.3", "version": "1.9.3"}, {"series": "4.0", "version": "4.0.7"}]}
        response = {"case": "article", "response": {"status": 200, "body": {"createdAt": "2026-01-02T03:04:05.123456Z", "token": "signed", "slug": "cafe", "tagList": ["ruby", "日本語"], "favorited": True}}}
        self.receipts = [{"runtime": runtime, "responses": [copy.deepcopy(response)]} for runtime in self.matrix["runtimes"]]

    def test_object_key_order_is_not_data(self):
        body = self.receipts[1]["responses"][0]["response"]["body"]
        self.receipts[1]["responses"][0]["response"]["body"] = dict(reversed(list(body.items())))
        self.assertEqual((2, 1), compare(self.matrix, self.receipts))

    def test_timestamp_token_slug_types_and_array_order_are_compared(self):
        for key, changed in [("createdAt", "different"), ("token", "changed"), ("slug", "caf"), ("tagList", ["日本語", "ruby"]), ("favorited", 1)]:
            with self.subTest(key=key):
                receipts = copy.deepcopy(self.receipts)
                receipts[1]["responses"][0]["response"]["body"][key] = changed
                with self.assertRaisesRegex(AssertionError, "response data differs"):
                    compare(self.matrix, receipts)

    def test_missing_duplicate_and_wrong_version_fail(self):
        for receipts in [self.receipts[:1], self.receipts + [self.receipts[0]], [{"runtime": {"series": "4.0", "version": "4.0.6"}, "responses": [1]}]]:
            with self.subTest(receipts=receipts):
                with self.assertRaises(AssertionError):
                    compare(self.matrix, receipts)

    def test_empty_or_truncated_response_transcript_fails(self):
        receipts = copy.deepcopy(self.receipts)
        receipts[1]["responses"] = []
        with self.assertRaises(AssertionError):
            compare(self.matrix, receipts)
        receipts[1]["responses"] = receipts[0]["responses"] * 2
        with self.assertRaisesRegex(AssertionError, "response data differs"):
            compare(self.matrix, receipts)


if __name__ == "__main__":
    unittest.main()
