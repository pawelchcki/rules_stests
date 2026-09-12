import json, os, subprocess, sys

def runfile(value):
    return value if os.path.isabs(value) else os.path.join(os.environ["TEST_SRCDIR"], value)
adapter, source = map(runfile, sys.argv[1:])

def run(method, headers, span, env=None):
    return subprocess.run(
        [adapter, "--source", source],
        input=json.dumps({"method": method, "headers": headers, "spans": [span] * 4}),
        text=True, capture_output=True, env=env,
    )

d001_headers = {
    "x-datadog-trace-id": "123456789", "x-datadog-parent-id": "987654321",
    "x-datadog-sampling-priority": "2", "x-datadog-origin": "synthetics;=web,z",
    "x-datadog-tags": "_dd.p.dm=-4",
}
d001 = {"trace_id": 123456789, "parent_id": 987654321, "span_id": 1,
        "meta": {"_dd.origin": "synthetics;=web,z", "_dd.p.dm": "-4"},
        "metrics": {"_sampling_priority_v1": 2}}
result = run("test_distributed_headers_extract_datadog_D001", d001_headers, d001)
assert result.returncode == 0, result.stderr
assert run("test_distributed_headers_extract_datadog_D001", d001_headers,
           {**d001, "meta": {**d001["meta"], "_dd.origin": "synthetics;=web"}}).returncode == 0
for mutation in (
    {"trace_id": 8}, {"parent_id": 8}, {"meta": {"_dd.origin": "wrong", "_dd.p.dm": "-4"}},
    {"meta": {"_dd.origin": "synthetics;=web,z"}}, {"metrics": {"_sampling_priority_v1": -1}},
):
    assert run("test_distributed_headers_extract_datadog_D001", d001_headers, {**d001, **mutation}).returncode != 0
assert run("test_distributed_headers_extract_datadog_D001", {**d001_headers, "x-datadog-trace-id": "8"}, d001).returncode != 0

d002_headers = {
    "x-datadog-trace-id": "0", "x-datadog-parent-id": "0",
    "x-datadog-sampling-priority": "2", "x-datadog-origin": "synthetics",
    "x-datadog-tags": "_dd.p.dm=-4",
}
d002 = {"trace_id": 8, "span_id": 1, "meta": {}, "metrics": {"_sampling_priority_v1": -1}}
result = run("test_distributed_headers_extract_datadog_invalid_D002", d002_headers, d002)
assert result.returncode == 0, result.stderr
for mutation in ({"trace_id": 0}, {"parent_id": 987654321}, {"meta": {"_dd.p.dm": "-4"}}, {"metrics": {"_sampling_priority_v1": 2}}):
    assert run("test_distributed_headers_extract_datadog_invalid_D002", d002_headers, {**d002, **mutation}).returncode != 0

optimized = dict(os.environ)
optimized["PYTHONOPTIMIZE"] = "1"
assert run("test_distributed_headers_extract_datadog_D001", d001_headers, d001, optimized).returncode != 0
print("pinned upstream D001/D002 assertions and mutation checks passed")
