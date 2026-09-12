#!/usr/bin/env python3
"""Execute pinned upstream Datadog header assertions on native spans."""
import argparse, hashlib, importlib.util, json, sys, types
from pathlib import Path

SOURCE_SHA256 = "eae879d44ecf020bb1f4a2899d78f2027c9942e556baf406932c2f9ad6905b43"
METHODS = {"test_distributed_headers_extract_datadog_D001", "test_distributed_headers_extract_datadog_invalid_D002"}


def only_span(traces):
    assert len(traces) == 1, traces
    assert len(traces[0]) == 1, traces[0]
    return traces[0][0]


def install_modules():
    def make(name):
        value = types.ModuleType(name)
        sys.modules[name] = value
        return value
    utils, features, scenarios = make("utils"), make("utils.features"), make("utils.scenarios")
    features.datadog_headers_propagation = scenarios.parametric = lambda value: value
    utils.features, utils.scenarios = features, scenarios
    docker, spec, trace = make("utils.docker_fixtures"), make("utils.docker_fixtures.spec"), make("utils.docker_fixtures.spec.trace")
    docker.TestAgentAPI = object
    trace.SAMPLING_PRIORITY_KEY, trace.ORIGIN = "_sampling_priority_v1", "_dd.origin"
    trace.find_only_span = only_span
    trace.span_has_no_parent = lambda span: "parent_id" not in span or span.get("parent_id") in (0, None)
    docker.spec, spec.trace = spec, trace
    package, conftest = make("upstream_parametric"), make("upstream_parametric.conftest")
    package.__path__ = []
    conftest.APMLibrary = object


class Agent:
    def __init__(self, span): self.span = span
    def wait_for_num_traces(self, count):
        assert count == 1
        return [[self.span]]


class Library:
    def __init__(self, headers): self.headers = headers
    def __enter__(self): return self
    def __exit__(self, *_): return False
    def dd_make_child_span_and_get_headers(self, headers):
        assert dict(headers) == self.headers, (headers, self.headers)
        return {}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    args = parser.parse_args()
    source = args.source.read_bytes()
    request = json.load(sys.stdin)
    if not __debug__:
        raise RuntimeError("upstream assertions require Python assertions enabled")
    if hashlib.sha256(source).hexdigest() != SOURCE_SHA256:
        raise RuntimeError("unexpected upstream source")
    if request.get("method") not in METHODS:
        raise RuntimeError("unsupported upstream method")
    if len(request.get("spans", ())) != 4:
        raise RuntimeError("expected exactly four server spans")
    install_modules()
    module_spec = importlib.util.spec_from_file_location("upstream_parametric.test_headers_datadog", args.source)
    upstream = importlib.util.module_from_spec(module_spec)
    module_spec.loader.exec_module(upstream)
    method = getattr(upstream.Test_Headers_Datadog(), request["method"])
    for span in request["spans"]:
        method(Agent(span), Library(request["headers"]))
    print(json.dumps({"sourceSha256": SOURCE_SHA256, "method": request["method"], "spans": 4}))


if __name__ == "__main__":
    main()
