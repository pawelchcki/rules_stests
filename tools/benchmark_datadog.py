#!/usr/bin/env python3
"""Five uncached executions of the original 34 combinations, on one executor."""
import argparse
import json
from pathlib import Path
import platform
import statistics
import subprocess
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--original", required=True, type=Path)
parser.add_argument("--original-output-base", required=True, type=Path)
parser.add_argument("--output", required=True, type=Path)
parser.add_argument("--jobs", type=int, default=4)
parser.add_argument("--original-revision", required=True)
parser.add_argument("--cold-output-root", type=Path, help="Optional fresh Bazel output bases for separate cold-build measurements")
args = parser.parse_args()
current = Path.cwd()


def verify_original_snapshot(snapshot: Path, revision: str) -> str:
    """Prove that an archive checkout still represents the stated revision.

    The benchmark intentionally accepts a Git-archive-style original tree,
    which has no .git directory.  Recording a revision string alone would let
    a changed archive be compared while claiming it was the original 34-case
    baseline.  Compare every tracked blob with the requested revision before
    creating benchmark output.  Git's --stdin-paths format is line based, so
    reject the (unsupported here) ambiguous newline path case explicitly.
    """
    resolved = subprocess.check_output(
        ["git", "rev-parse", revision + "^{commit}"], cwd=current, text=True
    ).strip()
    records = subprocess.check_output(
        ["git", "ls-tree", "-rz", resolved], cwd=current
    ).split(b"\0")[:-1]
    paths = []
    expected = []
    for record in records:
        header, path = record.split(b"\t", 1)
        _mode, kind, blob = header.split()
        if kind != b"blob":
            continue
        if b"\n" in path:
            raise RuntimeError(f"cannot verify newline-containing path {path!r}")
        paths.append(path)
        expected.append(blob)
    hashed = subprocess.run(
        ["git", "hash-object", "--no-filters", "--stdin-paths"],
        cwd=snapshot,
        input=b"\n".join(paths) + b"\n",
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if hashed.returncode:
        raise RuntimeError(
            "could not hash original snapshot against requested revision: "
            + hashed.stderr.decode(errors="replace")
        )
    actual = hashed.stdout.splitlines()
    if len(actual) != len(expected):
        raise RuntimeError(
            f"original snapshot hash count mismatch: expected {len(expected)}, got {len(actual)}"
        )
    for path, wanted, found in zip(paths, expected, actual):
        if wanted != found:
            raise RuntimeError(
                f"original snapshot differs from {resolved} at {path.decode(errors='backslashreplace')}"
            )
    return resolved


original_revision = verify_original_snapshot(args.original.resolve(), args.original_revision)
args.output.mkdir(parents=True, exist_ok=False)
variants = {
    "original": (args.original.resolve(), ["bazel", "--output_base=" + str(args.original_output_base.resolve())], ["//fixtures:datadog_suite"]),
    "compiled": (current, ["bazel"], ["//fixtures:aiohttp_datadog_hurl_test", "//fixtures:django_datadog_hurl_test", "//fixtures:aiohttp_datadog_v04_hurl_test_tags", "//fixtures:django_datadog_v04_hurl_test_tags"]),
}
flags = ["--config=local", f"--jobs={args.jobs}", f"--local_test_jobs={args.jobs}"]
results = {"originalRevision": original_revision, "currentRevision": subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(), "executor": platform.platform(), "jobs": args.jobs, "combinations": 34, "buildSeconds": {}, "executions": []}
if args.cold_output_root:
    args.cold_output_root.mkdir(parents=True, exist_ok=False)
    results["coldBuildSeconds"] = {}
    for variant, (cwd, _, targets) in variants.items():
        command = ["bazel", "--output_base=" + str((args.cold_output_root / variant).resolve())]
        started = time.monotonic()
        with (args.output / (variant + ".cold-build.log")).open("w") as log:
            subprocess.run(command + ["build"] + flags + targets, cwd=cwd, stdout=log, stderr=subprocess.STDOUT, check=True)
        results["coldBuildSeconds"][variant] = time.monotonic() - started
        (args.output / "results.json").write_text(json.dumps(results, indent=2))
        print(f"{variant} cold build: {results['coldBuildSeconds'][variant]:.3f}s", flush=True)
for variant, (cwd, command, targets) in variants.items():
    started = time.monotonic()
    with (args.output / (variant + ".build.log")).open("w") as log:
        subprocess.run(command + ["build"] + flags + targets, cwd=cwd, stdout=log, stderr=subprocess.STDOUT, check=True)
    results["buildSeconds"][variant] = time.monotonic() - started
# Alternate order to reduce systematic drift across five runs per variant.
for repetition in range(5):
    for variant in (list(variants) if repetition % 2 == 0 else list(reversed(variants))):
        cwd, command, targets = variants[variant]
        name = f"{variant}-{repetition + 1}"
        bep = (args.output / (name + ".bep.json")).resolve()
        started = time.monotonic()
        with (args.output / (name + ".log")).open("w") as log:
            subprocess.run(command + ["test"] + flags + ["--nocache_test_results", "--build_event_json_file=" + str(bep)] + targets, cwd=cwd, stdout=log, stderr=subprocess.STDOUT, check=True)
        wall = time.monotonic() - started
        attempts = []
        for line in bep.read_text().splitlines():
            event = json.loads(line)
            if "testResult" not in event:
                continue
            result = event["testResult"]
            if result["status"] != "PASSED" or result.get("cachedLocally") or result.get("executionInfo", {}).get("cachedRemotely"):
                raise RuntimeError(f"non-passing or cached benchmark attempt: {event}")
            attempts.append({"label": event["id"]["testResult"]["label"], "startMillis": int(result["testAttemptStartMillisEpoch"]), "durationMillis": int(result["testAttemptDurationMillis"])})
        if len(attempts) != 34 or len({a["label"] for a in attempts}) != 34:
            raise RuntimeError(f"expected exactly 34 independent attempts, got {len(attempts)}")
        window = (max(a["startMillis"] + a["durationMillis"] for a in attempts) - min(a["startMillis"] for a in attempts)) / 1000
        results["executions"].append({"variant": variant, "repetition": repetition + 1, "wallSeconds": wall, "testWindowSeconds": window, "attempts": attempts})
        (args.output / "results.json").write_text(json.dumps(results, indent=2))
        print(f"{name}: test window {window:.3f}s, invocation {wall:.3f}s", flush=True)
medians = {variant: statistics.median(r["testWindowSeconds"] for r in results["executions"] if r["variant"] == variant) for variant in variants}
results["medianTestWindowSeconds"] = medians
results["reduction"] = 1 - medians["compiled"] / medians["original"]
results["acceptancePassed"] = results["reduction"] >= 0.40
(args.output / "results.json").write_text(json.dumps(results, indent=2))
print(json.dumps({k: results[k] for k in ["medianTestWindowSeconds", "reduction", "acceptancePassed"]}, indent=2))
raise SystemExit(0 if results["acceptancePassed"] else 1)
