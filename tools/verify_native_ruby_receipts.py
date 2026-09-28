#!/usr/bin/env python3
"""Verify reviewed upstream Rails schema-v2 receipts and paired captures.

The compatibility specification is dd-trace-rb v2.42.0 at c48add11242b1cd50b59deb00ca044bd6db54626.
No Ruby tracer gem is loaded by this suite; these are native-tracer receipts.
"""

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys


def require(condition, message):
    if not condition:
        raise ValueError(message)


def is_json_integer(value):
    # bool is an int subclass in Python, but is not a JSON integer.
    return isinstance(value, int) and not isinstance(value, bool)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def verify_artifacts(manifest, manifest_path, policy):
    """Bind the manifest's implementation identity to the built native files."""
    libraries = "\n".join(manifest["libraries"])
    artifacts = re.findall(
        r"^; native-artifact ([A-Za-z0-9_.-]+) sha256:([0-9a-f]{64})$",
        libraries, re.MULTILINE)
    expected = set(policy["artifacts"])
    require(libraries.count("native-artifact") == len(artifacts) and
            len(artifacts) == len(expected) and
            {name for name, _ in artifacts} == expected,
            "invalid native artifact hashes in profile manifest")
    artifact_root = next((parent for parent in manifest_path.parents
                          if parent.name == "bazel-bin"), None)
    require(artifact_root is not None, "profile manifest must be under bazel-bin")
    for name, sha256 in artifacts:
        require(digest((artifact_root / name).read_bytes()) == sha256,
                f"{name}: built artifact hash differs from profile manifest")


def proof_key(proof):
    return tuple(proof[field] for field in ("featureId", "assertion", "basis"))


def flatten_spans(records):
    """Carry the containing chunk's 128-bit trace identity into each span."""
    chunks = []
    for record in records:
        for trace in record["payload"]["traces"]:
            if not trace:
                continue
            low_ids = {span["trace_id"] for span in trace}
            highs = {span["meta"].get("_dd.p.tid") for span in trace
                     if span["meta"].get("_dd.p.tid") is not None}
            require(len(low_ids) == 1 and len(highs) <= 1,
                    "Datadog chunk mixes trace identities")
            low = next(iter(low_ids))
            high = next(iter(highs), None)
            chunks.append((trace, low, high))
    spans = []
    for index, (trace, low, high) in enumerate(chunks):
        if high is None:
            # An untagged chunk cannot safely borrow high bits from another
            # chunk with the same low ID.
            high = ("untagged-chunk", index)
        for span in trace:
            spans.append({**span, "_trace_identity": (low, high)})
    return spans


def span_key(span):
    return span["_trace_identity"], span["span_id"]


def has_ancestor(span, spans, predicate):
    """Follow a local parent chain without relying on export order."""
    by_id = {span_key(candidate): candidate for candidate in spans}
    remaining = len(spans)
    while span["parent_id"] and remaining:
        span = by_id.get((span["_trace_identity"], span["parent_id"]))
        if span is None:
            return False
        if predicate(span):
            return True
        remaining -= 1
    return False


def receipt_test_target(profile, scenario, policy):
    template = policy["profiles"][profile]["testTarget"]
    return template.format(scenario=scenario,
                           scenario_suffix=scenario.removeprefix("native_"))


def receipt_directory(testlogs, profile, scenario, policy):
    # A smoke target can produce the same scenario receipt.  Bind evidence to
    # the canonical target so full-suite receipt verification is deterministic.
    outputs = testlogs / receipt_test_target(profile, scenario, policy) / "test.outputs"
    matches = list(outputs.glob(f"datadog/receipts/{profile}/{scenario}.json"))
    require(len(matches) == 1,
            f"{scenario}: expected one receipt for {profile}, found {len(matches)}")
    return matches[0].parent


# Authentication guards in the pinned Rails workload return these 401s before
# ActionController::Metal#process_action.  The source-defined Rack span is
# still required; an action-controller child is intentionally absent.
HALTED_401_CONTROLLERS = {
    "errors_articles": 14,
    "errors_auth": 18,
    "errors_comments": 8,
    "errors_profiles": 4,
}

REFERENCE_PROFILE = "ruby-rails-datadog-v2-42-0-v04"
REFERENCE_INSTANTIATIONS = {
    "articles": 66, "auth": 19, "comments": 43,
    "errors_articles": 20, "errors_auth": 10,
    "errors_authorization": 24, "errors_comments": 14,
    "errors_profiles": 2, "favorites": 29, "feed": 26,
    "pagination": 16, "profiles": 9, "propagation": 0,
    "propagation_datadog": 0, "tags": 8, "unicode": 0,
}


def validate_manifest(manifest, revision, policy):
    require(re.fullmatch(r"[0-9a-f]{40}", revision), "expected a full commit revision")
    require(manifest["family"] == "datadog" and manifest["wireVersion"] == "v0.4",
            "expected a Datadog v0.4 profile")
    require(manifest["application"] == policy["application"],
            "unexpected profile application")
    profile = manifest["profile"]
    scenarios = manifest["scenarios"]
    require(len(scenarios) == len(set(scenarios)), "duplicate profile scenarios")
    profile_policy = policy["profiles"].get(profile)
    require(profile_policy is not None, f"unexpected profile {profile}")
    kind = profile_policy["kind"]
    baseline, native, client = (kind == "baseline", kind == "native",
                                kind == "client")
    require(baseline or native or client, f"invalid profile kind {kind}")
    if baseline:
        require(set(scenarios) == set(REFERENCE_INSTANTIATIONS),
                "expected all 16 reviewed Rails scenarios")
        require(manifest.get("referenceProfile") == REFERENCE_PROFILE and
                manifest.get("referenceShapeNamespace") ==
                "datadog.realworld.shape." + REFERENCE_PROFILE and
                re.fullmatch(r"[0-9a-f]{64}", manifest.get("referenceProofPlanSha256", "")),
                "missing pinned upstream-reference provenance")
    elif native:
        require(set(scenarios) == {"native_concurrency", "native_malformed", "native_exceptions"},
                "unexpected native lifecycle scenarios")
    else:
        require(scenarios == ["native_ruby_client"], "unexpected Ruby client scenarios")
    require(manifest["serverOperation"] == policy["serverOperation"],
            "unexpected server operation")
    shapes = manifest.get("scenarioShapes", {})
    require(isinstance(shapes, dict), "invalid scenario shape manifest")
    if baseline:
        require(set(shapes) == set(scenarios) and all(shapes.values()),
                "all 16 Rails scenarios require reviewed upstream shapes")
    for field in ("validationPolicySha256", "candidateImplementationSha256"):
        require(re.fullmatch(r"[0-9a-f]{64}", manifest.get(field, "")),
                f"invalid {field}")
    plan = json.loads(manifest["proofPlan"])
    return profile, scenarios, baseline, client, shapes, plan


def verify(manifest, testlogs, revision, policy):
    profile, scenarios, baseline, client, shapes, plan = validate_manifest(
        manifest, revision, policy)
    service = policy["service"]
    total_spans = 0
    for scenario in scenarios:
        directory = receipt_directory(testlogs, profile, scenario, policy)
        receipt = json.loads((directory / (scenario + ".json")).read_bytes())
        capture_bytes = (directory / (scenario + ".capture.json")).read_bytes()
        shape = shapes.get(scenario, "")
        validation_mode = "exact" if shape else "contract"
        for key, expected in {
            "schemaVersion": 2, "family": "datadog", "wireVersion": "v0.4",
            "revision": revision, "profile": profile, "scenario": scenario,
            "validationMode": validation_mode, "outcome": "verified",
            "captureSha256": digest(capture_bytes),
            "proofPlanSha256": digest(manifest["proofPlan"].encode()),
            "validationPolicySha256": manifest["validationPolicySha256"],
            "candidateImplementationSha256": manifest["candidateImplementationSha256"],
        }.items():
            require(receipt.get(key) == expected, f"{scenario}: mismatched {key}")
        if baseline:
            require(receipt.get("referenceProfile") == REFERENCE_PROFILE and
                    receipt.get("referenceProofPlanSha256") ==
                    manifest["referenceProofPlanSha256"],
                    f"{scenario}: missing upstream-reference provenance")
        if validation_mode == "exact":
            require(receipt.get("scenarioShapeSha256") == digest(shape.encode()),
                    f"{scenario}: mismatched reviewed trace-shape hash")
        else:
            require(not receipt.get("scenarioShapeSha256"),
                    f"{scenario}: unexpected trace-shape hash")
        if client:
            wire_bytes = (directory / (scenario + ".wire.json")).read_bytes()
            require(receipt.get("auxiliaryEvidenceSha256") == digest(wire_bytes),
                    f"{scenario}: mismatched outgoing-propagation evidence hash")
            wire = json.loads(wire_bytes)
            require(isinstance(wire, list) and len(wire) == 3 and
                    [item.get("method") for item in wire] == ["GET", "GET", "POST"] and
                    all(item.get("traceparent") and item.get("datadog_parent") and
                        item.get("datadog_trace") and item.get("datadog_tags")
                        for item in wire),
                    f"{scenario}: incomplete outgoing-propagation evidence")
        else:
            require("auxiliaryEvidenceSha256" not in receipt,
                    f"{scenario}: unexpected auxiliary evidence")
        require(not receipt.get("xfailReason"), f"{scenario}: unexpected expected-failure evidence")
        wanted = [proof_key(proof) for proof in plan["proofs"]
                  if not proof.get("scenarios") or scenario in proof["scenarios"]]
        actual = [proof_key(proof) for proof in receipt["proofs"]]
        require(wanted and len(wanted) == len(set(wanted)) and
                len(actual) == len(set(actual)) and set(actual) == set(wanted) and
                all(proof["result"] == "pass" for proof in receipt["proofs"]),
                f"{scenario}: incomplete, duplicate, or failing proofs")
        coverage = receipt["coverage"]
        records = json.loads(capture_bytes)
        spans = flatten_spans(records)
        require(spans, f"{scenario}: empty capture")
        require(coverage["schemaVersion"] == 1 and coverage["application"] == policy["application"] and
                coverage["scenario"] == scenario and coverage["unclassifiedFields"] == 0,
                f"{scenario}: invalid field coverage")
        inventory = coverage["integrationSpans"]
        require(set(inventory) == {"http.server", "rails.controller", "database", "http.client"},
                f"{scenario}: invalid integration inventory")
        if client:
            require(inventory == {"http.server": 0, "rails.controller": 0,
                                  "database": 0, "http.client": 3} and
                    coverage["spanOccurrences"] == len(spans),
                    f"{scenario}: incomplete Ruby client coverage")
        else:
            require(inventory["http.server"] > 0 and
                    0 < inventory["rails.controller"] <= inventory["http.server"] and
                    inventory["database"] > 0 and
                    coverage["spanOccurrences"] == len(spans),
                    f"{scenario}: incomplete Rails integration coverage")
            expected_controllers = HALTED_401_CONTROLLERS.get(
                scenario, inventory["http.server"])
            require(inventory["rails.controller"] == expected_controllers,
                    f"{scenario}: unexpected controller inventory")
        policies = coverage["fieldPolicies"]
        require(set(policies) == {"exact", "normalized", "runtime-validated"} and
                all(is_json_integer(count) and count >= 0 for count in policies.values()) and
                coverage["fieldOccurrences"] == sum(policies.values()) > 0,
                f"{scenario}: invalid field-policy counts")
        identities = set()
        servers = []
        controllers = []
        database = []
        instantiations = []
        clients = []
        for span in spans:
            for key in ("trace_id", "span_id", "parent_id"):
                require(is_json_integer(span[key]) and
                        (0 if key == "parent_id" else 1) <= span[key] < 2**64,
                        f"{scenario}: invalid {key}")
            require(is_json_integer(span["start"]) and span["start"] > 0 and
                    is_json_integer(span["duration"]) and span["duration"] > 0,
                    f"{scenario}: incomplete span")
            high = span["meta"].get("_dd.p.tid")
            require(high is None or re.fullmatch(r"[0-9a-f]{16}", high),
                    f"{scenario}: invalid high trace ID")
            identity = span_key(span)
            require(identity not in identities, f"{scenario}: duplicate completed span")
            identities.add(identity)
            if span["name"] == "rack.request" and span["type"] == "web":
                require(span["service"] == service and span["resource"] and
                        span["meta"].get("span.kind") == "server" and
                        span["meta"].get("http.url"), f"{scenario}: invalid Rack server")
                servers.append(span)
            elif span["name"] == "rails.action_controller" and span["type"] == "web":
                require(span["service"] == service and span["resource"] and
                        span["meta"].get("rails.route.controller") and
                        span["meta"].get("rails.route.action"),
                        f"{scenario}: invalid controller span")
                controllers.append(span)
            elif span["name"] == "sqlite.query" and span["type"] == "sql":
                require(span["service"] == "sqlite" and span["resource"],
                        f"{scenario}: invalid SQLite span")
                database.append(span)
            elif span["name"] == "active_record.instantiation" and span["type"] == "custom":
                require(span["service"] == service and
                        span["meta"].get("active_record.instantiation.class_name") ==
                        span["resource"] and
                        type(span["metrics"].get("active_record.instantiation.record_count"))
                        in (int, float),
                        f"{scenario}: invalid ActiveRecord instantiation")
                instantiations.append(span)
            elif span["name"] == "http.request" and span["type"] == "http":
                require(span["meta"].get("span.kind") == "client",
                        f"{scenario}: invalid HTTP client span")
                clients.append(span)
        require(len(servers) == inventory["http.server"] and
                len(controllers) == inventory["rails.controller"] and
                len(database) == inventory["database"] and len(clients) == inventory["http.client"],
                f"{scenario}: inventory and capture disagree")
        if baseline:
            require(len(instantiations) == REFERENCE_INSTANTIATIONS[scenario],
                    f"{scenario}: incorrect instantiation coverage")
        if client:
            roots = [span for span in spans if span["parent_id"] == 0]
            require(len(spans) == 4 and len(roots) == 1 and
                    roots[0]["name"] == "ruby.http.fixture" and
                    all(span["parent_id"] == roots[0]["span_id"] for span in clients),
                    f"{scenario}: Net::HTTP spans are not children of the fixture root")
        else:
            require(all(span["parent_id"] in {server["span_id"] for server in servers
                                               if server["_trace_identity"] == span["_trace_identity"]}
                        for span in controllers),
                    f"{scenario}: controller is not a direct Rack child")
            controllers_by_server = {(span["_trace_identity"], span["parent_id"])
                                     for span in controllers}
            require(all(span_key(server) in controllers_by_server or
                        server["meta"].get("http.status_code") == "401"
                        for server in servers),
                    f"{scenario}: Rack span lacks controller without a halted 401")
            # A Rails before_action may issue User.find_by before
            # ActionController::Metal#process_action begins. Its SQL span is
            # therefore a direct Rack child; schema/lazy queries can also be
            # nested below another SQLite span. Every query must still belong
            # to the Rack request trace.
            require(all(has_ancestor(span, spans, lambda parent: parent in servers) for span in database),
                    f"{scenario}: SQLite span is not below its Rack request")
        if baseline and scenario in ("tags", "propagation", "propagation_datadog"):
            require(len(servers) == 4, f"{scenario}: expected exactly four Rack spans")
        if baseline and scenario in ("propagation", "propagation_datadog"):
            expected = {
                ("4bf92f3577b34da6", 11803532876627986230),
                ("8c1e0a5b6d2f4739", 9965072336285547154),
                ("b3f7d21c9e6a4805", 11276220234964099125),
            }
            children = [span for span in servers if span["parent_id"] != 0]
            roots = [span for span in servers if span["parent_id"] == 0]
            require(len(roots) == 1 and roots[0]["meta"]["http.method"] == "POST" and
                    roots[0]["meta"]["http.status_code"] == "201" and
                    roots[0]["meta"]["http.url"].endswith("/api/users") and
                    len(children) == 3 and
                    {(span["meta"].get("_dd.p.tid"), span["trace_id"])
                     for span in children} == expected and
                    all(span["parent_id"] == 67667974448284343 and
                        span["meta"]["http.method"] == "GET" and
                        span["meta"]["http.status_code"] == "200" and
                        span["meta"]["http.url"].endswith("/api/tags") for span in children),
                    f"{scenario}: incorrect registration or propagated context")
        elif baseline:
            require(all(span["parent_id"] == 0 for span in servers),
                    f"{scenario}: unpropagated requests inherited context")
        total_spans += len(servers)
        print(f"{scenario}: verified {validation_mode} receipt, {len(servers)} Rack server spans")
    modes = "exact" if shapes and all(shapes.get(scenario) for scenario in scenarios) else "contract"
    print(f"Verified {len(scenarios)} {modes} receipts and {total_spans} Rack server spans at {revision}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--testlogs", type=Path, required=True)
    parser.add_argument("--policy", type=Path, required=True)
    args = parser.parse_args()
    try:
        policy = json.loads(args.policy.read_bytes())
        require(isinstance(policy, dict) and
                isinstance(policy.get("artifacts"), list) and policy["artifacts"] and
                len(policy["artifacts"]) == len(set(policy["artifacts"])) and
                isinstance(policy.get("profiles"), dict) and policy["profiles"] and
                all(policy.get(key) for key in ("application", "serverOperation", "service")),
                "invalid native Ruby receipt policy")
        manifest = json.loads(args.manifest.read_bytes())
        verify_artifacts(manifest, args.manifest, policy)
        verify(manifest, args.testlogs, args.revision, policy)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"Native Ruby receipt verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
