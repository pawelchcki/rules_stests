#!/usr/bin/env python3
"""Update one entry in bazel/oci_images.lock.bzl without reformatting it."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


ENTRY_RE = re.compile(r'^    "(?P<name>[a-z0-9_]+)": struct\($')
TOP_LEVEL_ENTRY_RE = re.compile(r'^(?P<name>[A-Z][A-Z0-9_]+) = struct\($')
DIGEST_RE = re.compile(r'^\s+digest = "sha256:[0-9a-f]{64}",$')
TREE_RE = re.compile(r'^\s+tree = "(?:unpublished|[0-9a-f]{40})",$')


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--name", required=True)
    parser.add_argument("--digest", required=True)
    parser.add_argument("--tree", required=True)
    parser.add_argument("--lock", type=Path, default=Path("bazel/oci_images.lock.bzl"))
    args = parser.parse_args()

    if not re.fullmatch(r"sha256:[0-9a-f]{64}", args.digest):
        parser.error("--digest must be a sha256 OCI digest")
    if not re.fullmatch(r"[0-9a-f]{40}", args.tree):
        parser.error("--tree must be a 40-character Git tree OID")

    lines = args.lock.read_text(encoding="utf-8").splitlines()
    active_entry: str | None = None
    found_digest = False
    found_tree = False
    found_entry = False
    for index, line in enumerate(lines):
        match = ENTRY_RE.match(line)
        if match:
            active_entry = match.group("name")
            found_entry = found_entry or active_entry == args.name
            continue
        top_level_match = TOP_LEVEL_ENTRY_RE.match(line)
        if top_level_match:
            active_entry = top_level_match.group("name").lower()
            found_entry = found_entry or active_entry == args.name
            continue
        if active_entry == args.name and DIGEST_RE.match(line):
            indent = line[: len(line) - len(line.lstrip())]
            lines[index] = f'{indent}digest = "{args.digest}",'
            found_digest = True
        elif active_entry == args.name and TREE_RE.match(line):
            indent = line[: len(line) - len(line.lstrip())]
            lines[index] = f'{indent}tree = "{args.tree}",'
            found_tree = True
        elif active_entry and line in ("    ),", ")"):
            active_entry = None

    if not found_entry:
        parser.error(f"image entry {args.name!r} does not exist in {args.lock}")
    if not found_digest or not found_tree:
        parser.error(f"image entry {args.name!r} has an unexpected format")
    args.lock.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
