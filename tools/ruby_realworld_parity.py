"""Require identical RealWorld data from every pinned Ruby interpreter."""

import argparse
import difflib
import json
from pathlib import Path


def compare(matrix, receipts):
    expected = {runtime["series"]: runtime for runtime in matrix["runtimes"]}
    found = {}
    for receipt in receipts:
        runtime = receipt["runtime"]
        series = runtime["series"]
        if series in found:
            raise AssertionError(f"Duplicate response receipt for Ruby {series}")
        if runtime != expected.get(series):
            raise AssertionError(f"Response receipt has an unexpected runtime pin: {runtime}")
        if not receipt["responses"]:
            raise AssertionError(f"Ruby {series} recorded no RealWorld responses")
        found[series] = receipt
    if set(found) != set(expected):
        raise AssertionError(f"Missing Ruby response receipts: {sorted(set(expected) - set(found))}")
    reference = matrix["runtimes"][0]["series"]
    def canonical(value):
        return json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2)

    baseline = canonical(found[reference]["responses"])
    for series in expected:
        candidate = canonical(found[series]["responses"])
        if candidate != baseline:
            difference = "\n".join(difflib.unified_diff(
                baseline.splitlines(), candidate.splitlines(),
                fromfile=f"Ruby {reference}", tofile=f"Ruby {series}", lineterm="",
            ))
            raise AssertionError("RealWorld response data differs:\n" + difference)
    return len(found), len(found[reference]["responses"])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--matrix", type=Path, required=True)
    parser.add_argument("receipts", nargs="+", type=Path)
    args = parser.parse_args()
    matrix = json.loads(args.matrix.read_text())
    receipts = [json.loads(path.read_text()) for path in args.receipts]
    versions, responses = compare(matrix, receipts)
    print(f"All {versions} Ruby versions returned identical data for {responses} RealWorld HTTP requests.")


if __name__ == "__main__":
    main()
