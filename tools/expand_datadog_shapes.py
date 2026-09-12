#!/usr/bin/env python3
"""Losslessly expand compact reviewed Datadog trace-shape snapshots.

Snapshots store named native-field, metadata, metric, and span definitions per
profile. The expander restores the original Scheme layout byte-for-byte; the
hash lock makes every reviewed profile/scenario source an immutable contract.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from collections import Counter, defaultdict
from pathlib import Path


def scheme_format(value: object) -> str:
    if isinstance(value, str):
        return value
    if not isinstance(value, list):
        raise ValueError(f"invalid Scheme value {value!r}")
    if len(value) == 2 and value[0] == "native-fields" and isinstance(value[1], list) and all(isinstance(item, str) for item in value[1]):
        return "(native-fields (" + " ".join(value[1]) + " ))"
    output: list[str] = ["("]
    previous_atom = False
    for item in value:
        atom = isinstance(item, str)
        if atom and previous_atom:
            output.append(" ")
        output.append(scheme_format(item))
        previous_atom = atom
    return "".join(output) + ")"


def pretty_shape(shape: str) -> str:
    output: list[str] = []
    depth = 1
    quoted = False
    escaped = False
    for character in shape:
        if quoted:
            output.append(character)
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == '"':
                quoted = False
        elif character == '"':
            quoted = True
            output.append(character)
        elif character == "(":
            if output:
                while output and output[-1] == " ":
                    output.pop()
                output.append("\n" + "  " * depth)
            output.append(character)
            depth += 1
        elif character == ")":
            depth -= 1
            output.append(character)
        else:
            output.append(character)
    return "".join(output)


def source_for(profile: str, scenario: str, declaration: object) -> bytes:
    if not isinstance(declaration, dict):
        raise ValueError(f"profile {profile} is not an object")
    fields = declaration.get("fields")
    spans = declaration.get("spans")
    scenarios = declaration.get("scenarios")
    if not all(isinstance(value, dict) for value in (fields, spans, scenarios)):
        raise ValueError(f"profile {profile} has invalid compact definitions")
    groups = scenarios.get(scenario)
    if not isinstance(groups, list):
        raise ValueError(f"profile {profile} lacks scenario {scenario}")

    def resolve(value: object) -> object:
        if isinstance(value, dict):
            if set(value) != {"field"} or not isinstance(value["field"], str) or value["field"] not in fields:
                raise ValueError(f"profile {profile} has invalid field reference {value!r}")
            return fields[value["field"]]
        return value

    def span(reference: object, stack: tuple[str, ...] = ()) -> list[object]:
        if not isinstance(reference, str) or reference not in spans:
            raise ValueError(f"profile {profile} has invalid span reference {reference!r}")
        if reference in stack:
            raise ValueError(f"profile {profile} has recursive span {' -> '.join(stack + (reference,))}")
        definition = spans[reference]
        if not isinstance(definition, list):
            raise ValueError(f"profile {profile} span {reference} is not a list")
        result: list[object] = []
        for entry in definition:
            if not isinstance(entry, list) or len(entry) != 2 or not isinstance(entry[0], str):
                raise ValueError(f"profile {profile} span {reference} has invalid field")
            key, value = entry
            if key == "children":
                if not isinstance(value, list):
                    raise ValueError(f"profile {profile} span {reference} children are invalid")
                children = []
                for child in value:
                    if not isinstance(child, dict) or set(child) != {"span"}:
                        raise ValueError(f"profile {profile} span {reference} child is invalid")
                    children.append(span(child["span"], stack + (reference,)))
                result.append([key, children])
            else:
                result.append([key, resolve(value)])
        if not result or result[-1][0] != "children":
            raise ValueError(f"profile {profile} span {reference} lacks children")
        return result

    trace_shapes: list[object] = []
    for group in groups:
        if not isinstance(group, list) or len(group) != 2 or not isinstance(group[1], list):
            raise ValueError(f"profile {profile} scenario {scenario} has invalid trace group")
        trace_shapes.append([["count", group[0]], ["roots", [span(reference) for reference in group[1]]]])
    header = (
        f"(define-library (datadog realworld shape {profile} {scenario})\n"
        "  (export scenario-shape)\n"
        "  (import (scheme base) (datadog trace-shape))\n"
        "  (begin\n"
        "(define scenario-shape\n"
        "  '"
    )
    return (header + pretty_shape(scheme_format(trace_shapes)) + ")\n  ))\n").encode()


def read_snapshot(path: Path) -> dict[str, object]:
    data = json.loads(path.read_text())
    if not isinstance(data, dict) or data.get("format") != 2 or not isinstance(data.get("profiles"), dict):
        raise ValueError(f"invalid shape snapshot {path}")
    return data


def read_lock(path: Path) -> dict[str, str]:
    data = json.loads(path.read_text())
    if not isinstance(data, dict) or not all(isinstance(key, str) and isinstance(value, str) for key, value in data.items()):
        raise ValueError(f"invalid shape hash lock {path}")
    return data


def expand_shapes(snapshot_path: Path, output: Path, profiles: set[str], lock: dict[str, str] | None) -> None:
    profiles_data = read_snapshot(snapshot_path)["profiles"]
    assert isinstance(profiles_data, dict)
    unknown = profiles - set(profiles_data)
    if unknown:
        raise ValueError(f"unknown shape profile(s): {', '.join(sorted(unknown))}")
    names = [profile for profile in sorted(profiles_data) if not profiles or profile in profiles]
    expected_keys = {f"{profile}/{scenario}.scm" for profile in names for scenario in profiles_data[profile].get("scenarios", {})}  # type: ignore[union-attr]
    if lock is not None and not profiles and expected_keys != set(lock):
        raise ValueError("shape hash lock keyset differs from snapshots")
    for profile in names:
        declaration = profiles_data[profile]
        if not isinstance(declaration, dict) or not isinstance(declaration.get("scenarios"), dict):
            raise ValueError(f"profile {profile} has invalid scenarios")
        for scenario in declaration["scenarios"]:
            name = f"{profile}/{scenario}.scm"
            data = source_for(profile, scenario, declaration)
            if lock is not None:
                actual = hashlib.sha256(data).hexdigest()
                if lock.get(name) != actual:
                    raise ValueError(f"expanded shape hash mismatch for {name}: got {actual}, want {lock.get(name)}")
            destination = output / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(data)


def _tokens(source: str):
    index = 0
    while index < len(source):
        character = source[index]
        if character.isspace():
            index += 1
        elif character in "()'":
            yield character
            index += 1
        elif character == '"':
            end, escaped = index + 1, False
            while end < len(source):
                if source[end] == '"' and not escaped:
                    break
                escaped = source[end] == "\\" and not escaped
                if source[end] != "\\":
                    escaped = False
                end += 1
            yield source[index:end + 1]
            index = end + 1
        else:
            end = index
            while end < len(source) and not source[end].isspace() and source[end] not in "()'":
                end += 1
            yield source[index:end]
            index = end


def _parse(tokens_value):
    iterator = iter(tokens_value)

    def value(item: str | None = None):
        item = next(iterator) if item is None else item
        if item == "(":
            result = []
            while True:
                child = next(iterator)
                if child == ")":
                    return result
                result.append(value(child))
        if item == "'":
            return ["quote", value()]
        return item

    return value()


def _slug(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", value.strip('"').lower()).strip("-")[:28] or "span"


def _snapshot_json(value: object, indent: int = 0) -> str:
    """Render dictionaries readably while retaining dense span/list payloads."""
    if isinstance(value, dict):
        if not value:
            return "{}"
        prefix = " " * (indent + 2)
        keys = (
            ["fields", "spans", "scenarios"]
            if set(value) == {"fields", "spans", "scenarios"}
            else sorted(value)
        )
        members = [
            prefix + json.dumps(key) + ": " + _snapshot_json(value[key], indent + 2)
            for key in keys
        ]
        return "{\n" + ",\n".join(members) + "\n" + " " * indent + "}"
    return json.dumps(value, separators=(",", ":"))


def factor(sources: Path, snapshot: Path, lock_path: Path) -> None:
    """Factor canonical <profile>/<scenario>.scm sources into a stable snapshot."""
    profile_scenarios: dict[str, dict[str, object]] = defaultdict(dict)
    lock: dict[str, str] = {}
    for path in sorted(sources.glob("*/*.scm")):
        source = path.read_text()
        quote = source.index("'", source.index("(define scenario-shape"))
        parsed = _parse(_tokens(source[quote:]))
        if not isinstance(parsed, list) or len(parsed) != 2 or parsed[0] != "quote":
            raise ValueError(f"invalid scenario shape source {path}")
        profile_scenarios[path.parent.name][path.stem] = parsed[1]
        lock[f"{path.parent.name}/{path.name}"] = hashlib.sha256(source.encode()).hexdigest()

    def profile_data(scenarios: dict[str, object]) -> dict[str, object]:
        usages: Counter[tuple[str, str]] = Counter()
        contexts: dict[tuple[str, str], list[str]] = defaultdict(list)

        def scan(value: object) -> None:
            if not isinstance(value, list):
                raise ValueError("invalid span")
            name = next((entry[1] for entry in value if isinstance(entry, list) and entry[0] == "name"), "span")
            for entry in value:
                if not isinstance(entry, list) or len(entry) != 2:
                    raise ValueError("invalid span field")
                key, contents = entry
                if key == "children":
                    if not isinstance(contents, list):
                        raise ValueError("invalid children")
                    for child in contents:
                        scan(child)
                elif key in ("native-fields", "meta", "metrics"):
                    encoded = json.dumps(contents, separators=(",", ":"))
                    usages[(key, encoded)] += 1
                    contexts[(key, encoded)].append(str(name))

        for groups in scenarios.values():
            if not isinstance(groups, list):
                raise ValueError("invalid scenario groups")
            for group in groups:
                if not isinstance(group, list) or len(group) != 2 or not isinstance(group[1], list):
                    raise ValueError("invalid trace group")
                for root in group[1][1]:
                    scan(root)

        fields: dict[str, object] = {}
        field_refs: dict[tuple[str, str], str] = {}
        sequence: Counter[str] = Counter()
        for (key, encoded), count in sorted(usages.items()):
            if count >= 2:
                sequence[key] += 1
                identifier = f"{key}-{_slug(contexts[(key, encoded)][0])}-{sequence[key]:03d}"
                fields[identifier] = json.loads(encoded)
                field_refs[(key, encoded)] = identifier

        spans: dict[str, object] = {}
        by_structure: dict[str, str] = {}
        span_sequence: Counter[str] = Counter()

        def intern(value: object) -> str:
            if not isinstance(value, list):
                raise ValueError("invalid span")
            name = next((entry[1] for entry in value if isinstance(entry, list) and entry[0] == "name"), "span")
            resource = next((entry[1] for entry in value if isinstance(entry, list) and entry[0] == "resource"), "")
            compact = []
            for entry in value:
                if not isinstance(entry, list) or len(entry) != 2:
                    raise ValueError("invalid span field")
                key, contents = entry
                if key == "children":
                    if not isinstance(contents, list):
                        raise ValueError("invalid children")
                    contents = [{"span": intern(child)} for child in contents]
                else:
                    encoded = json.dumps(contents, separators=(",", ":"))
                    if (key, encoded) in field_refs:
                        contents = {"field": field_refs[(key, encoded)]}
                compact.append([key, contents])
            structure = json.dumps(compact, separators=(",", ":"), sort_keys=True)
            if structure in by_structure:
                return by_structure[structure]
            prefix = _slug(str(name))
            span_sequence[prefix] += 1
            identifier = f"{prefix}-{_slug(str(resource))}-{span_sequence[prefix]:03d}"
            spans[identifier] = compact
            by_structure[structure] = identifier
            return identifier

        compact_scenarios = {}
        for name, groups in scenarios.items():
            compact_scenarios[name] = [[group[0][1], [intern(root) for root in group[1][1]]] for group in groups]  # type: ignore[index]
        return {"fields": fields, "spans": spans, "scenarios": compact_scenarios}

    data = {
        "format": 2,
        "profiles": {profile: profile_data(scenarios) for profile, scenarios in sorted(profile_scenarios.items())},
    }
    snapshot.write_text(_snapshot_json(data) + "\n")
    lock_path.write_text(json.dumps(dict(sorted(lock.items())), indent=2) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--snapshot", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--hash-lock", type=Path)
    parser.add_argument("--profile", action="append", default=[])
    parser.add_argument("--factor", type=Path, help="factor canonical <profile>/<scenario>.scm sources")
    args = parser.parse_args()
    if args.factor:
        if not args.hash_lock:
            parser.error("--factor requires --hash-lock")
        factor(args.factor, args.snapshot, args.hash_lock)
        return
    if not args.output_dir:
        parser.error("expansion requires --output-dir")
    expand_shapes(args.snapshot, args.output_dir, set(args.profile), read_lock(args.hash_lock) if args.hash_lock else None)


if __name__ == "__main__":
    main()
