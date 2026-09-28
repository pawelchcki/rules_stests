"""Launch the pinned Python tracer and verify native trace and carrier evidence."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time
from urllib.error import URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

REVISION = "255dc57d719c4d33a1c45a1b41cd517c5cae5878"
UPSTREAM = "https://github.com/DataDog/system-tests/blob/" + REVISION + "/tests/parametric/"
SOURCE_HASHES = {
    "test_span_sampling.py": "263984b8af6ce361d2561cdf74b5bec4f42a6e6351af477a2f7924b5dea4b490",
    "test_headers_datadog.py": "eae879d44ecf020bb1f4a2899d78f2027c9942e556baf406932c2f9ad6905b43",
    "test_headers_tracecontext.py": "3f039084c528e318329cffe8a2f7345770f9ae4474449465b58154447111ae1d",
    "test_headers_b3.py": "0ea2de7ab49539cd7abf147560e53355bb5165ca1ea9e741c310d219af1609e9",
    "test_headers_b3multi.py": "99cdfb974407d5673d74ba4f57a60ed095a2d4d93a5e72c9965a751472d1adb2",
    "test_headers_none.py": "f4990e85f9c003d0b8a89581f56576a0bf0d8e1627711e8d0cf7ea5132c1afae",
    "test_headers_precedence.py": "4d6dd200460abcc9f1faae28ec8757436b9e366e631b0f8ef35eb369f5d66b45",
}

# These are local cases derived from upstream methods; upstream tests are not executed here.
CASES = [
    dict(name="inject-datadog", style="datadog", formats=["datadog"], source="test_headers_datadog.py", method="test_distributed_headers_inject_datadog_D003"),
    dict(name="inject-tracecontext", style="tracecontext", formats=["tracecontext"], source="test_headers_tracecontext.py", method="test_tracestate_w3c_p_inject"),
    dict(name="inject-b3", style="b3", formats=["b3"], source="test_headers_b3.py", method="test_headers_b3_inject_valid"),
    dict(name="inject-b3multi", style="b3multi", formats=["b3multi"], source="test_headers_b3multi.py", method="test_headers_b3multi_inject_valid"),
    dict(name="inject-none", style="none", formats=[], source="test_headers_none.py", method="test_headers_none_inject"),
    dict(name="inject-multiple", style="datadog,tracecontext,b3,b3multi", formats=["datadog", "tracecontext", "b3", "b3multi"], source="test_headers_precedence.py", method="test_headers_precedence_propagationstyle_datadog_tracecontext"),
    dict(name="inject-none-with-datadog", style="none,datadog", formats=["datadog"], source="test_headers_none.py", method="test_headers_none_inject_with_other_propagators"),
    dict(name="sample-match", rules=[{"service": "lab-service", "name": "lab.request"}], expected=1, source="test_span_sampling.py", method="test_single_rule_match_span_sampling_sss001"),
    dict(name="sample-glob", rules=[{"service": "lab-*", "name": "lab.re?uest"}], expected=1, source="test_span_sampling.py", method="test_special_glob_characters_span_sampling_sss002"),
    dict(name="sample-no-match", rules=[{"service": "other", "name": "other"}], expected=None, source="test_span_sampling.py", method="test_single_rule_no_match_span_sampling_sss003"),
    dict(name="sample-service-only", rules=[{"service": "lab-service"}], expected=1, source="test_span_sampling.py", method="test_single_rule_only_service_pattern_match_span_sampling_sss004"),
    dict(name="sample-name-no-match", rules=[{"name": "other"}], expected=None, source="test_span_sampling.py", method="test_single_rule_only_name_pattern_no_match_span_sampling_sss005"),
    dict(name="sample-first-keep", rules=[{"service": "lab-service", "name": "lab.request"}, {"service": "lab-service", "name": "lab.request", "sample_rate": 0}], expected=1, source="test_span_sampling.py", method="test_multi_rule_keep_drop_span_sampling_sss006"),
    dict(name="sample-first-drop", rules=[{"service": "lab-service", "name": "lab.request", "sample_rate": 0}, {"service": "lab-service", "name": "lab.request"}], expected=None, source="test_span_sampling.py", method="test_multi_rule_drop_keep_span_sampling_sss007"),
    dict(name="sample-zero", rules=[{"service": "lab-service", "name": "lab.request", "sample_rate": 0}], expected=None, source="test_span_sampling.py", method="test_multi_rule_drop_keep_span_sampling_sss007"),
    dict(name="sample-explicit-one", rules=[{"service": "lab-service", "name": "lab.request", "sample_rate": 1}], expected=1, source="test_span_sampling.py", method="test_single_rule_always_keep_span_sampling_sss011"),
    dict(name="sample-kept-trace", rules=[{"service": "lab-service", "name": "lab.request"}], expected=None, trace_keep=True, source="test_span_sampling.py", method="test_single_rule_always_keep_span_sampling_sss011"),
    dict(name="sample-kept-zero", rules=[{"service": "lab-service", "name": "lab.request", "sample_rate": 0}], expected=None, trace_keep=True, source="test_span_sampling.py", method="test_single_rule_tracer_always_keep_span_sampling_sss012"),
]

BASE_ENV = {
    "DD_SERVICE": "datadog-python-lab", "DD_ENV": "test", "DD_VERSION": "1",
    "DD_TRACE_ENABLED": "true", "DD_TRACE_RATE_LIMIT": "-1",
    "DD_TRACE_WRITER_INTERVAL_SECONDS": "0.1", "DD_TRACE_PARTIAL_FLUSH_ENABLED": "false",
    "DD_TRACE_128_BIT_TRACEID_GENERATION_ENABLED": "true",
    "DD_TRACE_PROPAGATION_STYLE_EXTRACT": "none",
    "DD_TRACE_PROPAGATION_STYLE_INJECT": "datadog",
    "DD_INSTRUMENTATION_TELEMETRY_ENABLED": "false", "DD_REMOTE_CONFIGURATION_ENABLED": "false",
    "DD_RUNTIME_METRICS_ENABLED": "false", "DD_PROFILING_ENABLED": "false",
    "DD_APPSEC_ENABLED": "false", "DD_IAST_ENABLED": "false", "DD_SCA_ENABLED": "false",
    "DD_DYNAMIC_INSTRUMENTATION_ENABLED": "false", "DD_EXCEPTION_REPLAY_ENABLED": "false",
    "DD_DATA_STREAMS_ENABLED": "false", "DD_LLMOBS_ENABLED": "false",
    "DD_LOGS_INJECTION": "false", "DD_TRACE_COMPUTE_STATS": "false",
    "DD_TRACE_STATS_COMPUTATION_ENABLED": "false", "DD_TRACE_STARTUP_LOGS": "false",
    "DD_TRACE_SAMPLING_RULES": '[{"sample_rate":1}]',
}
FORMATS = {
    "datadog": {"x-datadog-trace-id", "x-datadog-parent-id", "x-datadog-sampling-priority", "x-datadog-tags", "x-datadog-origin"},
    "tracecontext": {"traceparent", "tracestate"},
    "b3": {"b3"},
    "b3multi": {"x-b3-traceid", "x-b3-spanid", "x-b3-sampled", "x-b3-flags", "x-b3-parentspanid"},
}


def get(url, method="GET"):
    with urlopen(Request(url, method=method), timeout=5) as response:
        return response.read()


def sha(data):
    return hashlib.sha256(data).hexdigest()


def _parse_unique_fields(value, separator, assignment, whitespace=False):
    fields = {}
    for raw in value.split(separator):
        field = raw.strip() if whitespace else raw
        assert field and field.count(assignment) == 1, value
        key, item = field.split(assignment, 1)
        assert key and item and key not in fields, value
        fields[key] = item
    return fields


def assert_carrier(carrier, formats, identity):
    lowered = [key.lower() for key in carrier]
    assert len(lowered) == len(set(lowered)), carrier
    carrier = {key.lower(): value for key, value in carrier.items()}
    allowed = set().union(*(FORMATS[fmt] for fmt in formats)) if formats else set()
    assert set(carrier) <= allowed, (carrier, allowed)
    root = int(identity["root_id"])
    full = int(identity["trace_id"])
    low = full & ((1 << 64) - 1)
    assert 0 < full >> 64 < (1 << 64) and root > 0 and root < (1 << 64), identity
    assert int(identity["root_parent_id"]) == 0, identity
    if "datadog" in formats:
        assert int(carrier["x-datadog-trace-id"]) == low, carrier
        assert int(carrier["x-datadog-parent-id"]) == root, carrier
        assert int(carrier["x-datadog-sampling-priority"]) == identity["priority"], carrier
        if full >> 64:
            tags = _parse_unique_fields(carrier["x-datadog-tags"], ",", "=")
            assert tags.get("_dd.p.tid") == f"{full >> 64:016x}", carrier
    if "tracecontext" in formats:
        state = _parse_unique_fields(carrier["tracestate"], ",", "=", whitespace=True)
        dd = _parse_unique_fields(state["dd"], ";", ":")
        assert dd.get("p") == f"{root:016x}" and dd.get("s") == str(identity["priority"]), carrier
        version, trace, parent, flags = carrier["traceparent"].split("-")
        assert version == "00" and len(trace) == 32 and len(parent) == 16 and len(flags) == 2, carrier
        assert int(trace, 16) == full and int(parent, 16) == root, carrier
        assert int(flags, 16) & 1 == (1 if identity["priority"] > 0 else 0), carrier
    if "b3" in formats:
        parts = carrier["b3"].split("-")
        assert len(parts[0]) == 32 and len(parts[1]) == 16, carrier
        assert int(parts[0], 16) == full and int(parts[1], 16) == root, carrier
        assert parts[2] == ("d" if identity["priority"] > 1 else "1" if identity["priority"] == 1 else "0"), carrier
    if "b3multi" in formats:
        assert int(carrier["x-b3-traceid"], 16) == full, carrier
        assert int(carrier["x-b3-spanid"], 16) == root, carrier
        assert len(carrier["x-b3-traceid"]) == 32 and len(carrier["x-b3-spanid"]) == 16, carrier
        priority = identity["priority"]
        if priority > 1:
            assert carrier.get("x-b3-flags") == "1" and "x-b3-sampled" not in carrier, carrier
        else:
            assert carrier.get("x-b3-sampled") == ("1" if priority == 1 else "0") and "x-b3-flags" not in carrier, carrier
    if not formats:
        assert not carrier, carrier


def decoded_spans(capture, wire):
    records = json.loads(capture)
    assert isinstance(records, list), records
    assert all(record["payload"]["wire_version"] == wire for record in records), records
    chunks = [chunk for record in records for chunk in record["payload"]["traces"]]
    assert all(chunk for chunk in chunks), chunks
    return [span for chunk in chunks for span in chunk]


def assert_graph(spans, identity, case):
    assert len(spans) == 2, spans
    ids = {int(span["span_id"]): span for span in spans}
    assert len(ids) == 2, spans
    root = ids[int(identity["root_id"])]
    child = ids[int(identity["child_id"])]
    assert int(identity["child_parent_id"]) == int(identity["root_id"]), identity
    assert int(root.get("parent_id", 0)) == 0, root
    assert int(child.get("parent_id", 0)) == int(identity["root_id"]), child
    assert root["name"] == identity["name"] and root["service"] == identity["service"], root
    assert child["name"] == "lab.child" and child["service"] == "lab-child", child
    low = int(identity["trace_id"]) & ((1 << 64) - 1)
    assert all(int(span["trace_id"]) == low for span in spans), spans
    high = int(identity["trace_id"]) >> 64
    if high:
        tids = [span.get("meta", {}).get("_dd.p.tid") for span in spans]
        assert all(tid in (None, f"{high:016x}") for tid in tids) and any(tids), spans
    assert all(int(span["start"]) > 0 and int(span["duration"]) > 0 and int(span.get("error", 0)) == 0 for span in spans), spans
    priority = 2 if case.get("trace_keep", "rules" not in case) else -1
    assert root.get("metrics", {}).get("_sampling_priority_v1") == priority, root
    assert identity["priority"] == priority, identity
    markers = ("_dd.span_sampling.rule_rate", "_dd.span_sampling.mechanism", "_dd.span_sampling.max_per_second")
    expected = case.get("expected")
    root_metrics = root.get("metrics", {})
    child_metrics = child.get("metrics", {})
    if expected is None:
        assert all(marker not in root_metrics and marker not in child_metrics for marker in markers), spans
    else:
        assert root_metrics.get(markers[0]) == expected and root_metrics.get(markers[1]) == 8, root
        assert markers[2] not in root_metrics, root
        assert all(marker not in child_metrics for marker in markers), child


def case_environment(args, sink, case):
    env = dict(BASE_ENV)
    env["DD_TRACE_AGENT_URL"] = sink
    env["DD_TRACE_API_VERSION"] = args.wire
    if "style" in case:
        env["DD_TRACE_PROPAGATION_STYLE_INJECT"] = case["style"]
    if "rules" in case:
        env["DD_SPAN_SAMPLING_RULES"] = json.dumps(case["rules"], separators=(",", ":"))
        env["DD_TRACE_SAMPLING_RULES"] = '[{"sample_rate":1}]' if case.get("trace_keep") else '[{"sample_rate":0}]'
    return env


def run_case(args, sink, out, case, index):
    name = case["name"]
    get(sink + "/reset?protocol=datadog", "POST")
    env = case_environment(args, sink, case)
    ready = out / (name + ".port")
    ready.unlink(missing_ok=True)
    log_path = out / (name + ".app.log")
    launch = [args.launcher, "--runtime=python", "--rootfs=" + args.rootfs]
    launch += args.injection_flags
    launch += ["--instance=datadog-lab-" + name + "-" + str(index)]
    launch += ["--env=" + key + "=" + value for key, value in sorted(env.items())]
    launch += ["--", args.app, "--ready-file", str(ready)]
    proc_env = {key: value for key, value in os.environ.items() if not key.startswith(("DD_", "OTEL_")) and key != "PYTHONOPTIMIZE"}
    with log_path.open("wb") as log:
        proc = subprocess.Popen(launch, stdout=log, stderr=log, env=proc_env, start_new_session=True)
        try:
            deadline = time.monotonic() + 30
            while not ready.exists():
                assert proc.poll() is None, f"{name} exited: {log_path.read_text(errors='replace')}"
                assert time.monotonic() < deadline, f"{name} readiness timed out: {log_path.read_text(errors='replace')}"
                time.sleep(0.1)
            app_url = "http://127.0.0.1:" + ready.read_text().strip()
            while True:
                assert proc.poll() is None, f"{name} exited: {log_path.read_text(errors='replace')}"
                assert time.monotonic() < deadline, f"{name} health timed out: {log_path.read_text(errors='replace')}"
                try:
                    get(app_url + "/healthz")
                    break
                except URLError:
                    time.sleep(0.1)
            identity_bytes = get(app_url + "/run?" + urlencode({"service": "lab-service", "name": "lab.request"}))
            identity = json.loads(identity_bytes)
            (out / (name + ".identity.json")).write_bytes(identity_bytes)
            capture = b""
            for _ in range(40):
                capture = get(sink + "/dump?protocol=datadog")
                (out / (name + ".capture.json")).write_bytes(capture)
                spans = decoded_spans(capture, args.wire)
                if len(spans) >= 2:
                    break
                time.sleep(0.1)
            assert identity["service"] == "lab-service" and identity["name"] == "lab.request", identity
            assert_graph(spans, identity, case)
            assert_carrier(identity["carrier"], case.get("formats", ["datadog"]), identity)
            return {
                "name": name, "status": "passed", "wire": args.wire,
                "source": UPSTREAM + case["source"] + "#" + case["method"],
                "sourceSha256": SOURCE_HASHES[case["source"]], "sourceMethod": case["method"],
                "workloadSha256": sha(Path(args.app).read_bytes()),
                "configuration": env, "captureSha256": sha(capture),
                "identitySha256": sha(identity_bytes), "carrier": identity["carrier"],
                "traceId": identity["trace_id"], "rootId": identity["root_id"], "childId": identity["child_id"],
            }
        finally:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()


def resolve(path):
    candidate = Path(path)
    if candidate.exists():
        return str(candidate.resolve())
    for root in (os.environ.get("RUNFILES_DIR"), os.environ.get("TEST_SRCDIR")):
        if root and (Path(root) / path).exists():
            return str((Path(root) / path).resolve())
    raise FileNotFoundError(path)


def main():
    if not __debug__:
        raise RuntimeError("Datadog lab assertions require Python optimization disabled")
    parser = argparse.ArgumentParser()
    parser.add_argument("--wire", choices=["v0.4", "v0.5"], required=True)
    parser.add_argument("--launcher", required=True)
    parser.add_argument("--rootfs", required=True)
    parser.add_argument("--app", required=True)
    parser.add_argument("--injection-flag", action="append", default=[], dest="injection_flags")
    args = parser.parse_args()
    args.launcher = resolve(args.launcher)
    args.rootfs = resolve(args.rootfs)
    args.app = resolve(args.app)
    args.injection_flags = ["--instrumentation-rootfs=" + resolve(flag.split("=", 1)[1]) if flag.startswith("--instrumentation-rootfs=") else flag for flag in args.injection_flags]
    ports = json.loads(os.environ["ASSIGNED_PORTS"])
    matches = [int(value) for key, value in ports.items() if key.endswith("//harness:otel_sink_service")]
    assert len(matches) == 1, ports
    sink = "http://127.0.0.1:" + str(matches[0])
    assert os.environ.get("TEST_UNDECLARED_OUTPUTS_DIR"), "TEST_UNDECLARED_OUTPUTS_DIR is required"
    out = Path(os.environ["TEST_UNDECLARED_OUTPUTS_DIR"])
    out.mkdir(parents=True, exist_ok=True)
    results = []
    try:
        for index, case in enumerate(CASES):
            try:
                result = run_case(args, sink, out, case, index)
            except Exception as error:
                capture_path = out / (case["name"] + ".capture.json")
                identity_path = out / (case["name"] + ".identity.json")
                results.append({
                    "name": case["name"], "status": "failed", "detail": repr(error), "wire": args.wire,
                    "source": UPSTREAM + case["source"] + "#" + case["method"],
                    "sourceSha256": SOURCE_HASHES[case["source"]], "sourceMethod": case["method"],
                    "workloadSha256": sha(Path(args.app).read_bytes()),
                    "configuration": case_environment(args, sink, case),
                    "captureSha256": sha(capture_path.read_bytes()) if capture_path.exists() else None,
                    "identitySha256": sha(identity_path.read_bytes()) if identity_path.exists() else None,
                })
                raise
            results.append(result)
            print(args.wire, case["name"], "passed", flush=True)
    finally:
        (out / "datadog-lab-results.json").write_text(json.dumps({"schemaVersion": 1, "wire": args.wire, "results": results}, indent=2) + "\n")
    assert len(results) == len(CASES)


if __name__ == "__main__":
    main()
