#!/usr/bin/env python3
"""Regression coverage for lossless Datadog shape snapshot expansion."""
from __future__ import annotations

import json
import os
import tempfile
from pathlib import Path

import expand_datadog_shapes as expander


def run(snapshot: Path, lock: Path, output: Path) -> None:
    expander.expand_shapes(snapshot, output, set(), expander.read_lock(lock))


def main() -> None:
    runfiles = (
        Path(os.environ["TEST_SRCDIR"]) / os.environ["TEST_WORKSPACE"]
        if "TEST_SRCDIR" in os.environ
        else Path(__file__).resolve().parent.parent
    )
    snapshot = runfiles / "corpus/datadog/realworld/shape_snapshot/snapshots.json"
    lock = runfiles / "corpus/datadog/realworld/shape_snapshot/hashes.json"
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        run(snapshot, lock, root / "expanded")

        regenerated = root / "regenerated.json"
        regenerated_lock = root / "regenerated-lock.json"
        expander.factor(root / "expanded", regenerated, regenerated_lock)
        if regenerated.read_bytes() != snapshot.read_bytes():
            raise AssertionError("factoring did not reproduce the checked-in snapshot")
        run(regenerated, regenerated_lock, root / "reexpanded")
        if expander.read_lock(regenerated_lock) != expander.read_lock(lock):
            raise AssertionError("factor did not preserve every source hash")
        regenerated_again = root / "regenerated-again.json"
        regenerated_again_lock = root / "regenerated-again-lock.json"
        expander.factor(root / "expanded", regenerated_again, regenerated_again_lock)
        if regenerated.read_bytes() != regenerated_again.read_bytes():
            raise AssertionError("factoring is not stable")

        changed = root / "changed.json"
        changed.write_text(snapshot.read_text().replace("django.request", "xjango.request", 1))
        try:
            run(changed, lock, root / "changed")
        except ValueError as error:
            if "hash mismatch" not in str(error):
                raise AssertionError(f"changed snapshot failed for the wrong reason: {error}") from error
        else:
            raise AssertionError("changed snapshot did not fail its lock")

        omitted = root / "omitted.json"
        data = json.loads(snapshot.read_text())
        profile = next(iter(data["profiles"].values()))
        profile["scenarios"].pop(next(iter(profile["scenarios"])))
        omitted.write_text(json.dumps(data))
        try:
            run(omitted, lock, root / "omitted")
        except ValueError as error:
            if "keyset" not in str(error):
                raise AssertionError(f"omitted snapshot failed for the wrong reason: {error}") from error
        else:
            raise AssertionError("omitted snapshot did not fail its lock")


if __name__ == "__main__":
    main()
