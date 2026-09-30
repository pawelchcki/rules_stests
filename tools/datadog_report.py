#!/usr/bin/env python3
"""Render a standalone Datadog report only after rechecking retained evidence."""
import argparse
from collections import Counter
import html
import hashlib
import json
from pathlib import Path
import re
import subprocess


def read_execution(directory, revision, gate):
    manifests = sorted(directory.glob("*.profile.json"))
    if not manifests:
        raise ValueError(f"{directory}: no profile manifests")
    command = [str(gate.resolve()), "--revision", revision]
    profiles = []
    for path in manifests:
        manifest = json.loads(path.read_text())
        profile = manifest["profile"]
        if not re.fullmatch(r"[a-z0-9-]+", profile):
            raise ValueError("invalid profile path")
        command += ["--manifest", str(path.resolve())]
        scenarios = []
        for scenario in manifest["scenarios"]:
            if not re.fullmatch(r"[a-z0-9_]+", scenario):
                raise ValueError("invalid scenario path")
            receipt = directory / profile / scenario / "datadog/receipts" / profile / f"{scenario}.json"
            capture = receipt.with_name(f"{scenario}.capture.json")
            command += ["--receipt", str(receipt.resolve()), "--capture", str(capture.resolve())]
            scenarios.append(json.loads(receipt.read_text()))
        profiles.append({"profile": profile, "manifestSha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                         "application": manifest["application"],
                         "wireVersion": manifest["wireVersion"], "scenarios": scenarios})
    # A stored success log is not sufficient: the gate must inspect the current
    # captures, exact proof sets, revisions, and compiled bytecode again.
    subprocess.run(command, check=True, capture_output=True, text=True)
    return profiles


def build_report(executions, revision, gate):
    if not executions:
        raise ValueError("at least one retained execution is required")
    if len({directory.resolve() for directory in executions}) != len(executions):
        raise ValueError("executions must be separate retained directories")
    runs = [read_execution(directory, revision, gate) for directory in executions]
    identities = [{(p["profile"], s["scenario"]) for p in run for s in p["scenarios"]} for run in runs]
    if any(identity != identities[0] for identity in identities[1:]):
        raise ValueError("retained executions have different scenario/profile coverage")
    contracts = [{p["profile"]: p["manifestSha256"] for p in run} for run in runs]
    if any(contract != contracts[0] for contract in contracts[1:]):
        raise ValueError("retained executions have different profile contracts")
    # Keep each run's occurrence counts separate; repeated executions do not
    # multiply the number of verified capabilities or distinct scenarios.
    return {"revision": revision, "executions": runs}


def render(report):
    esc = lambda value: html.escape(str(value), quote=True)
    rows, details = [], []
    latest = report["executions"][-1]
    for profile in latest:
        policies = Counter()
        features = set()
        span_count = 0
        for receipt in profile["scenarios"]:
            coverage = receipt["coverage"]
            policies.update(coverage["fieldPolicies"])
            span_count += coverage["spanOccurrences"]
            scenario_features = {proof["featureId"] for proof in receipt["proofs"]}
            features.update(scenario_features)
            proofs = "".join(f'<li>{esc(p["featureId"])}: {esc(p["assertion"])} <small>({esc(p["basis"])})</small></li>'
                             for p in receipt["proofs"])
            details.append(f'<details data-search="{esc(profile["profile"])} {esc(receipt["scenario"])} {esc(" ".join(sorted(scenario_features)))}">'
                           f'<summary>{esc(profile["profile"])} / {esc(receipt["scenario"])} — verified</summary>'
                           f'<p>Capture SHA-256: <code>{esc(receipt["captureSha256"])}</code></p><ul>{proofs}</ul></details>')
        values = [profile["profile"], profile["application"], profile["wireVersion"], len(profile["scenarios"]),
                  len(features), span_count, policies["exact"], policies["normalized"], policies["runtime-validated"]]
        rows.append('<tr data-search="' + esc(" ".join(map(str, values)) + " " + " ".join(sorted(features))) + '">' +
                    "".join(f"<td>{esc(value)}</td>" for value in values) + "</tr>")
    count = sum(len(profile["scenarios"]) for profile in latest)
    data = json.dumps(report, separators=(",", ":")).replace("<", "\\u003c").replace("&", "\\u0026")
    return f'''<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Datadog tracing evidence</title>
<style>
:root{{color-scheme:light dark;font:16px/1.55 system-ui,sans-serif}}body{{max-width:1200px;margin:3rem auto;padding:0 1.5rem}}
h1{{line-height:1.15}}input{{font:inherit;padding:.6rem;width:min(90%,32rem)}}table{{border-collapse:collapse;width:100%;font-size:.9rem}}
th,td{{text-align:left;border-bottom:1px solid #8886;padding:.6rem;vertical-align:top}}.scroll{{overflow:auto}}
details{{border-bottom:1px solid #8886;padding:.7rem 0}}summary{{cursor:pointer}}code{{overflow-wrap:anywhere}}small{{opacity:.75}}
[hidden]{{display:none!important}}
</style><main>
<h1>Datadog tracing evidence</h1>
<p><strong>{count} distinct scenarios verified across {len(latest)} profiles</strong> in {len(report["executions"])} retained executions.</p>
<p>Revision: <code>{esc(report["revision"])}</code></p>
<p>These results establish the selected exact-shape contracts and their authored assertions.
They do not establish complete upstream parity. Unsupported external probes and products outside this tracing matrix do not count as verified capabilities.</p>
<label for="filter">Filter by profile, scenario, or feature</label><br><input id="filter" type="search" placeholder="e.g. rails, propagation, sampling">
<h2>Profile coverage</h2><p>Span and field counts below describe the last retained execution. Repeated executions do not multiply distinct scenario or feature counts. Each profile's feature count is independent.</p>
<div class="scroll"><table><thead><tr>{''.join(f'<th scope="col">{heading}</th>' for heading in ['Profile','Application','Intake','Scenarios','Features','Spans','Exact fields','Normalized fields','Runtime validated fields'])}</tr></thead>
<tbody>{''.join(rows)}</tbody></table></div>
<h2>Scenario evidence</h2>{''.join(details)}
<h2>Verification boundary</h2><p>Every execution was rechecked by the Datadog coverage gate before rendering.
The gate requires current-revision schema-v2 verified receipts, complete scenario coverage, passing proof sets,
capture and shape digest bindings, matching compiled validators, and zero unclassified fields.
Full manifests, captures, validators, logs, and timing evidence are retained separately in the CI evidence archive.</p>
</main><script id="evidence" type="application/json">{data}</script>
<script>document.getElementById('filter').addEventListener('input',event=>{{const query=event.target.value.toLowerCase();document.querySelectorAll('[data-search]').forEach(row=>{{row.hidden=!row.dataset.search.toLowerCase().includes(query)}})}});</script></html>'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execution", action="append", type=Path, required=True)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--gate", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        report = build_report(args.execution, args.revision, args.gate)
        args.output.write_text(render(report), encoding="utf-8")
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Datadog report rejected: {error}\n")


if __name__ == "__main__":
    main()
