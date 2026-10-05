"""Embed accepted Ruby API matrix results into the self-contained report."""

import argparse
import base64
import gzip
import json
from pathlib import Path
import re
from urllib.parse import unquote, urlparse
import zipfile


PAYLOAD = re.compile(r'(<script[^>]*id="report-data"[^>]*>)(.*?)(</script>)', re.S)
PARITY_FILE = "ruby-matrix-parity.json"


def local_artifact(uri):
    parsed = urlparse(uri)
    if parsed.scheme != "file" or parsed.netloc not in ("", "localhost"):
        raise ValueError("Ruby parity outputs must be downloaded locally; use --remote_download_outputs=toplevel")
    return Path(unquote(parsed.path))


def parity_summary(outputs):
    found = []
    for output in outputs:
        name = output.get("name", "")
        if not (name.endswith(".zip") or name.endswith(PARITY_FILE)):
            continue
        path = local_artifact(output.get("uri", ""))
        if name.endswith(".zip"):
            with zipfile.ZipFile(path) as archive:
                for entry in archive.namelist():
                    if Path(entry).name == PARITY_FILE:
                        found.append(json.loads(archive.read(entry)))
        elif path.name == PARITY_FILE:
            found.append(json.loads(path.read_text()))
    if len(found) != 1:
        raise ValueError("Expected exactly one Ruby response-parity summary in test outputs")
    return found[0]


def matrix_result(plan, events, revision, source_root):
    if not re.fullmatch(r"[0-9a-f]{40}", revision):
        raise ValueError("Ruby matrix revision must be a 40-character commit SHA")
    runtimes = plan["runtimes"]
    expected = {label for runtime in runtimes for label in plan["tests"][runtime["series"]]}
    expected.add(plan["parityTest"])
    summaries, results = {}, {}
    for event in events:
        for kind, target in (("testSummary", summaries), ("testResult", results)):
            label = event.get("id", {}).get(kind, {}).get("label")
            if label in expected and kind in event:
                if kind == "testSummary" and label in target:
                    raise ValueError(f"Duplicate Ruby test summary: {label}")
                target.setdefault(label, []).append(event[kind])
    missing = expected - summaries.keys()
    if missing:
        raise ValueError(f"Missing Ruby test results: {sorted(missing)}")
    for label, values in summaries.items():
        if values[0].get("overallStatus") != "PASSED":
            raise ValueError(f"Ruby test did not pass: {label}")
    parity_runs = results.get(plan["parityTest"], [])
    passing = [result for result in parity_runs if result.get("status") == "PASSED"]
    if len(passing) != 1:
        raise ValueError("Expected one passing Ruby response-parity test result")
    summary = parity_summary(passing[0].get("testActionOutput", []))
    if summary.get("schemaVersion") != 1 or summary.get("runtimes") != runtimes:
        raise ValueError("Ruby parity runtime pins do not match the report plan")
    if type(summary.get("responseCount")) is not int or summary["responseCount"] <= 0:
        raise ValueError("Ruby parity summary contains no responses")
    if not re.fullmatch(r"[0-9a-f]{64}", summary.get("responseSha256", "")):
        raise ValueError("Ruby parity summary has no valid response digest")
    versions = []
    for runtime in runtimes:
        tests = []
        for label in plan["tests"][runtime["series"]]:
            observed = results.get(label, [])
            if not observed:
                raise ValueError(f"Missing Ruby test execution: {label}")
            tests.append({"label": label, "status": "passed", "cached": all(
                result.get("cachedLocally", False) or result.get("executionInfo", {}).get("cachedRemotely", False)
                for result in observed
            )})
        versions.append({"runtime": runtime, "tests": tests})
    return {
        "revision": revision,
        "sourceUrl": source_root.rstrip("/") + "/fixtures/apps/ruby/realworld-sinatra/matrix.json",
        "versions": versions,
        "testCount": len(expected),
        "responseCount": summary["responseCount"],
        "responseSha256": summary["responseSha256"],
        "parityStatus": "passed",
        "parityCached": bool(passing[0].get("cachedLocally", False) or passing[0].get("executionInfo", {}).get("cachedRemotely", False)),
    }


def embed(html, result):
    matches = list(PAYLOAD.finditer(html))
    if len(matches) != 1:
        raise ValueError("Expected one embedded report data payload")
    match = matches[0]
    model = json.loads(gzip.decompress(base64.b64decode(match[2])))
    model["rubyMatrix"] = result
    payload = base64.b64encode(gzip.compress(json.dumps(model, ensure_ascii=False, separators=(",", ":")).encode(), mtime=0)).decode()
    return html[:match.start(2)] + payload + html[match.end(2):]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--plan", type=Path, required=True)
    parser.add_argument("--bep", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--source-root", required=True)
    args = parser.parse_args()
    events = [json.loads(line) for line in args.bep.read_text().splitlines() if line.strip()]
    result = matrix_result(json.loads(args.plan.read_text()), events, args.revision, args.source_root)
    html = embed(args.report.read_text(), result)
    if len(html.encode()) > 5 * 1024 * 1024:
        raise ValueError("Report exceeds the public artifact size limit")
    args.report.write_text(html)


if __name__ == "__main__":
    main()
