#!/usr/bin/env python3
"""Checks the shape renderer against the Scheme vocabulary it writes for.

The renderer's Python model and corpus/datadog/shape/*.scm must agree: every
canonical candidate in testdata/ is rendered, and the sink's Scheme VM has to
evaluate the rendering back to exactly the candidate's datum. Every checked-in
reviewed shape must evaluate, and mutations must be explained.

usage: datadog_shapes_test.py SINK SHAPE_DIRECTORY LIBRARY...
"""
from __future__ import annotations

import re
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import datadog_shapes

TESTDATA = Path(__file__).parent / "testdata" / "datadog_candidates"


class Sink:
    def __init__(self, executable: Path, directory: Path):
        with socket.socket() as probe:
            probe.bind(("127.0.0.1", 0))
            self.port = probe.getsockname()[1]
        self.process = subprocess.Popen(
            [str(executable), "--port", str(self.port), "--output", str(directory / f"sink-{self.port}.json")],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        deadline = time.monotonic() + 30
        while True:
            try:
                urllib.request.urlopen(f"http://127.0.0.1:{self.port}/info", timeout=1).read()
                return
            except OSError:
                if time.monotonic() > deadline:
                    raise
                time.sleep(0.05)

    def evaluate(self, source: str) -> tuple[int, str]:
        request = urllib.request.Request(
            f"http://127.0.0.1:{self.port}/validate?protocol=datadog", data=source.encode(), method="POST",
            headers={"Content-Type": "text/x-scheme"})
        try:
            with urllib.request.urlopen(request, timeout=600) as response:
                return response.status, response.read().decode()
        except urllib.error.HTTPError as error:
            return error.code, error.read().decode()

    def close(self) -> None:
        self.process.kill()
        self.process.wait()


def library_name(source: str) -> str:
    start = source.index("(define-library (") + len("(define-library (")
    return source[start:source.index(")", start)]


def comparison(core: str, rendered: str, candidate: str) -> str:
    """A program printing EQUAL, or the matcher's explanation."""
    candidate = candidate.replace(f"(define-library ({library_name(candidate)})", "(define-library (candidate)", 1)
    return (
        core + rendered + "\n" + candidate + "\n"
        "(import (scheme base) (scheme write) (datadog trace-shape match)"
        f" (prefix ({library_name(rendered)}) rendered:) (prefix (candidate) candidate:))\n"
        '(display (or (trace-shape-difference rendered:scenario-shape candidate:scenario-shape) "EQUAL"))\n'
    )


def main() -> None:
    sink_path, shapes, *libraries = sys.argv[1:]
    core = "".join(Path(path).read_text() + "\n" for path in libraries)
    failures: list[str] = []
    with tempfile.TemporaryDirectory() as temporary:
        sinks = [Sink(Path(sink_path), Path(temporary)) for _ in range(4)]
        try:
            def check_candidate(index_and_path: tuple[int, Path]) -> None:
                index, path = index_and_path
                profile, scenario = path.parent.name, path.stem
                candidate = path.read_text()
                rendered = datadog_shapes.render_file(profile, scenario, candidate)
                if '(span "' in rendered:
                    failures.append(f"{profile}/{scenario}: fell back to generic spans")
                status, output = sinks[index % len(sinks)].evaluate(comparison(core, rendered, candidate))
                if (status, output) != (200, "EQUAL"):
                    failures.append(f"{profile}/{scenario}: rendered shape differs: {status} {output[:500]}")

            candidates = sorted(TESTDATA.glob("*/*.scm"))
            if len(candidates) < 10:
                failures.append("candidate testdata is missing")
            with ThreadPoolExecutor(len(sinks)) as pool:
                list(pool.map(check_candidate, enumerate(candidates)))

            # A changed tag is reported with the span path that leads to it.
            path = TESTDATA / "python-aiohttp-datadog-v4-14-0-v04" / "unicode.scm"
            candidate = path.read_text()
            rendered = datadog_shapes.render_file(path.parent.name, path.stem, candidate)
            observed = re.search(r'\("http\.status_code" "(\d{3})"\)', candidate).group(1)
            mutated = candidate.replace(f'("http.status_code" "{observed}")', '("http.status_code" "599")', 1)
            status, output = sinks[0].evaluate(comparison(core, rendered, mutated))
            if mutated == candidate or status != 200 or f'tag http.status_code expected "{observed}" but was "599"' not in output:
                failures.append(f"status mutation was not explained: {status} {output[:500]}")
            # A renamed child span is reported too.
            mutated = candidate.replace('(name "sqlite.query")', '(name "sqlite.other")', 1)
            status, output = sinks[0].evaluate(comparison(core, rendered, mutated))
            if mutated == candidate or status != 200 or "child span is missing" not in output:
                failures.append(f"child mutation was not explained: {status} {output[:500]}")

            # Spans outside the vocabulary are rendered generically and still exact.
            unknown = candidate.replace('(name "sqlite.query")', '(name "custom.operation")', 1)
            rendered = datadog_shapes.render_file(path.parent.name, path.stem, unknown)
            status, output = sinks[0].evaluate(comparison(core, rendered, unknown))
            if '(span "custom.operation"' not in rendered or (status, output) != (200, "EQUAL"):
                failures.append(f"generic rendering is not exact: {status} {output[:500]}")

            # Every reviewed shape evaluates within the VM's budgets; one
            # program per profile keeps the vocabulary compiled once.
            reviewed = sorted(Path(shapes).glob("*/*.scm"))
            if len(reviewed) != 112:
                failures.append(f"expected 112 reviewed shapes, found {len(reviewed)}")
            profiles = sorted({path.parent for path in reviewed})

            def check_profile(index_and_directory: tuple[int, Path]) -> None:
                index, directory = index_and_directory
                sources = [path.read_text() for path in sorted(directory.glob("*.scm"))]
                imports = " ".join(f"(prefix ({library_name(source)}) s{number}:)" for number, source in enumerate(sources))
                checks = " ".join(f"(check s{number}:scenario-shape)" for number in range(len(sources)))
                program = (core + "".join(source + "\n" for source in sources) +
                           f"(import (scheme base) (scheme write) {imports})\n"
                           "(define (check shape) (if (and (pair? shape) (list? shape)) #t (error \"empty shape\")))\n"
                           f"{checks}\n(display \"EVALUATED\")\n")
                status, output = sinks[index % len(sinks)].evaluate(program)
                if (status, output) != (200, "EVALUATED"):
                    failures.append(f"{directory}: {status} {output[:500]}")

            with ThreadPoolExecutor(len(sinks)) as pool:
                list(pool.map(check_profile, enumerate(profiles)))
        finally:
            for sink in sinks:
                sink.close()
    if failures:
        raise SystemExit("\n".join(failures))
    print(f"PASS {len(candidates)} candidates, {len(reviewed)} reviewed shapes")


if __name__ == "__main__":
    main()
