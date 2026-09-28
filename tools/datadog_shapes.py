#!/usr/bin/env python3
"""Render reviewed Datadog trace shapes in the readable shape vocabulary.

The sink reports a scenario's native Datadog topology as a canonical datum
(`/candidate?protocol=datadog`). This tool rewrites such candidates with the
integration builders in corpus/datadog/shape/, so a reviewer reads

    (django-request "GET" "api/tags" 200 (url "/api/tags") ...
      (sqlite "SELECT ..."))

instead of every native field of every span. The Python model below mirrors
the Scheme vocabulary; a rendered shape is only written after the model
evaluates it back to exactly the candidate's datum, and the Bazel suite then
checks the Scheme evaluation of the same file against live captures.

    datadog_shapes.py render --profile <id> --scenario <name> candidate.scm > shape.scm
    datadog_shapes.py render-tree --profile <id> <candidate-dir> <shape-dir>
"""
from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

# ---------------------------------------------------------------------------
# Canonical datum


class Symbol(str):
    """A bare Scheme symbol, distinguished from strings."""


def tokens(source: str):
    index = 0
    while index < len(source):
        character = source[index]
        if character.isspace():
            index += 1
        elif character == ";":
            while index < len(source) and source[index] != "\n":
                index += 1
        elif character in "()'":
            yield character
            index += 1
        elif character == '"':
            end = index + 1
            while source[end] != '"':
                end += 2 if source[end] == "\\" else 1
            yield source[index:end + 1]
            index = end + 1
        else:
            end = index
            while end < len(source) and not source[end].isspace() and source[end] not in "()'\";":
                end += 1
            yield source[index:end]
            index = end


def unescape(literal: str) -> str:
    body, result, index = literal[1:-1], [], 0
    while index < len(body):
        if body[index] != "\\":
            result.append(body[index])
            index += 1
            continue
        escape = body[index + 1]
        if escape == "x":
            end = body.index(";", index)
            result.append(chr(int(body[index + 2:end], 16)))
            index = end + 1
            continue
        result.append({"n": "\n", "r": "\r", "t": "\t"}.get(escape, escape))
        index += 2
    return "".join(result)


def parse(source: str) -> list[object]:
    stream = iter(tokens(source))

    def value(token: str) -> object:
        if token == "(":
            items = []
            for item in stream:
                if item == ")":
                    return items
                items.append(value(item))
            raise ValueError("unbalanced parentheses")
        if token == "'":
            return [Symbol("quote"), value(next(stream))]
        if token.startswith('"'):
            return unescape(token)
        try:
            number = float(token)
        except ValueError:
            return Symbol(token)
        # The validator VM has no flonums: 1.0 reads as the integer 1.
        if number != int(number):
            raise ValueError(f"non-integral number {token} is not representable")
        return int(number)

    return [value(token) for token in stream]


@dataclass
class Span:
    native_fields: frozenset[str]
    service: str
    name: str
    type: str
    resource: str
    parent_kind: str
    error: int
    meta: dict[str, str]
    metrics: dict[str, object]
    children: list["Span"]
    remote: tuple[str, str, str] | None = None  # parent-id, trace-id, trace-id-high

    def key(self) -> tuple:
        return (
            self.native_fields, self.service, self.name, self.type, self.resource,
            self.parent_kind, self.error, tuple(sorted(self.meta.items())),
            tuple(sorted((k, repr(v)) for k, v in self.metrics.items())), self.remote,
            tuple(sorted(child.key() for child in self.children)),
        )


def span_from_datum(datum: list) -> Span:
    fields = {entry[0]: entry[1] for entry in datum}
    remote = None
    if "parent-id" in fields:
        remote = (fields["parent-id"], fields["trace-id"], fields["trace-id-high"])
    return Span(
        native_fields=frozenset(fields["native-fields"]),
        service=fields["service"], name=fields["name"], type=fields["type"],
        resource=fields["resource"], parent_kind=fields["parent-kind"], error=fields["error"],
        meta={key: value for key, value in fields["meta"]},
        metrics={key: value for key, value in fields["metrics"]},
        children=[span_from_datum(child) for child in fields["children"]],
        remote=remote,
    )


def read_candidate(source: str) -> list[tuple[int, list[Span]]]:
    """Reads `(define scenario-shape '...)` in candidate or library form."""
    for form in parse(source):
        found = find_shape(form)
        if found is not None:
            groups = found[1] if isinstance(found, list) and found and found[0] == "quote" else None
            if groups is None:
                raise ValueError("scenario-shape is not a quoted canonical datum")
            result = []
            for group in groups:
                fields = {entry[0]: entry[1] for entry in group}
                result.append((fields["count"], [span_from_datum(root) for root in fields["roots"]]))
            return result
    raise ValueError("missing scenario-shape definition")


def find_shape(form: object):
    if isinstance(form, list):
        if len(form) == 3 and form[0] == "define" and form[1] == "scenario-shape":
            return form[2]
        for item in form:
            found = find_shape(item)
            if found is not None:
                return found
    return None


# ---------------------------------------------------------------------------
# The vocabulary model (mirrors corpus/datadog/trace-shape.scm and shape/*.scm)

APP_SERVICE = "<service>"


@dataclass
class Clause:
    kind: str
    args: tuple
    text: str = ""  # how a shape spells this clause, "" for vocabulary internals


@dataclass
class Node:
    name: str
    resource: str
    clauses: list  # Clause | Node


@dataclass
class Caller:
    style: str
    trace_id: str
    parent_id: str
    trace_id_high: str
    priority: int
    header: str | None
    text: str


def tag(key, value, text=""):
    return Clause("tag", (key, value), text or f"(tag {q(key)} {q(value)})")


def untag(key):
    return Clause("untag", (key,), f"(untag {q(key)})")


def metric(key, value, text=""):
    return Clause("metric", (key, value), text or f"(metric {q(key)} {lit(value)})")


def unmetric(key):
    return Clause("unmetric", (key,), f"(unmetric {q(key)})")


def service(name):
    return Clause("service", (name,), f"(service {q(name)})")


def span_type(value):
    return Clause("type", (value,), f"(span-type {q(value)})")


def raised(kind, message):
    return Clause("raised", (kind, message), f"(raised {q(kind)} {q(message)})")


def mark(name, text):
    return Clause("mark", (name,), text)


def q(value: str) -> str:
    out = ['"']
    for character in value:
        if character == '"':
            out.append('\\"')
        elif character == "\\":
            out.append("\\\\")
        elif character == "\n":
            out.append("\\n")
        elif character == "\r":
            out.append("\\r")
        elif character == "\t":
            out.append("\\t")
        elif ord(character) < 32 or 0x7F <= ord(character) < 0xA0:
            out.append(f"\\x{ord(character):x};")
        else:
            out.append(character)
    out.append('"')
    return "".join(out)


def lit(value: object) -> str:
    return q(value) if isinstance(value, str) else str(value)


def hex_to_decimal(text: str) -> str:
    return str(int(text, 16))


def traceparent(header: str) -> Caller:
    return Caller("w3c", hex_to_decimal(header[19:35]), hex_to_decimal(header[36:52]), header[3:19],
                  1 if header[53:55] == "01" else 0, header, f"(continues (traceparent {q(header)}))")


def datadog_headers(trace_id: str, parent_id: str, priority: int, high: str) -> Caller:
    return Caller("datadog", trace_id, parent_id, high, priority, None,
                  f"(continues (datadog-headers {q(trace_id)} {q(parent_id)} {priority} {q(high)}))")


@dataclass
class Tracer:
    exception_stack: str
    native_fields: Callable
    trace_root: Callable
    every_span: Callable
    service_entry: list
    marks: dict


def evaluate_span(tracer: Tracer, node: Node, parent_service: str | None, caller: Caller | None) -> Span:
    clauses = [clause for clause in node.clauses if isinstance(clause, Clause)]
    root = parent_service is None
    own_service = APP_SERVICE
    for clause in clauses:
        if clause.kind == "service":
            own_service = clause.args[0]
    entry = root or own_service != parent_service
    derived = list(tracer.every_span(caller))
    if root:
        derived += tracer.trace_root(caller)
    if entry:
        derived += tracer.service_entry
    if own_service != APP_SERVICE:
        derived.append(tag("_dd.base_service", APP_SERVICE))
    for clause in clauses:
        if clause.kind == "mark":
            derived += tracer.marks[clause.args[0]]
    error, meta, metrics, kind_type = 0, {}, {}, ""
    for clause in derived + clauses:
        if clause.kind == "tag":
            meta.pop(clause.args[0], None)
            meta[clause.args[0]] = clause.args[1]
        elif clause.kind == "untag":
            meta.pop(clause.args[0], None)
        elif clause.kind == "metric":
            metrics.pop(clause.args[0], None)
            metrics[clause.args[0]] = clause.args[1]
        elif clause.kind == "unmetric":
            metrics.pop(clause.args[0], None)
        elif clause.kind == "type":
            kind_type = clause.args[0]
        elif clause.kind == "raised":
            error = 1
            meta["error.type"] = clause.args[0]
            meta["error.message"] = clause.args[1]
            meta[tracer.exception_stack] = "<validated-stack>"
    parent_kind = "child" if not root else ("remote" if caller else "root")
    children = [evaluate_span(tracer, child, own_service, caller) for child in node.clauses if isinstance(child, Node)]
    return Span(
        native_fields=frozenset(tracer.native_fields(parent_kind, error, kind_type, meta, metrics)),
        service=own_service, name=node.name, type=kind_type, resource=node.resource,
        parent_kind=parent_kind, error=error, meta=meta, metrics=metrics, children=children,
        remote=(caller.parent_id, caller.trace_id, caller.trace_id_high) if root and caller else None,
    )


# -- tracers (corpus/datadog/shape/tracers.scm) -------------------------------

V05_FIELDS = ["duration", "error", "meta", "metrics", "name", "parent_id", "resource", "service",
              "span_id", "start", "trace_id", "type"]


def python_v04_fields(kind, error, span_kind, meta, metrics):
    names = ["duration", "name", "resource", "service", "span_id", "start", "trace_id"]
    if meta:
        names.append("meta")
    if metrics:
        names.append("metrics")
    if error != 0:
        names.append("error")
    if kind != "root":
        names.append("parent_id")
    if span_kind:
        names.append("type")
    return names


def fixed_fields(*names):
    return lambda *_: list(names)


ENV = tag("env", "test")
VERSION = tag("version", "1")


def kept_by_sampling_rule():
    return [tag("_dd.p.dm", "-3"), tag("_dd.p.ksr", "1"), metric("_dd.rule_psr", 1), metric("_dd.limit_psr", 1)]


def priority(caller):
    return metric("_sampling_priority_v1", caller.priority if caller else 2)


def process_identity(language):
    return [tag("language", language), tag("runtime-id", "<runtime-id>"), metric("process_id", "<process-id>")]


def dd_trace_py(wire: str, process_tags: str) -> Tracer:
    def root(caller):
        clauses = [tag("_dd.p.tid", "<trace-id-high>"), tag("_dd.tags.process", process_tags),
                   *process_identity("python"), metric("_dd.tracer_kr", 1), priority(caller)]
        if not caller:
            clauses += kept_by_sampling_rule()
        elif caller.style == "w3c":
            clauses.append(tag("traceparent", caller.header))
        return clauses

    def every(caller):
        clauses = [ENV]
        if caller and caller.style == "datadog":
            clauses.append(tag("_dd.p.tid", "<trace-id-high>"))
        return clauses

    return Tracer("error.stack",
                  python_v04_fields if wire == "v0.4" else fixed_fields(*V05_FIELDS),
                  root, every, [metric("_dd.top_level", 1)], {})


def dd_trace_rb(process_tags: str) -> Tracer:
    def root(caller):
        clauses = [tag("_dd.p.tid", "<trace-id-high>"), *process_identity("ruby"),
                   metric("_dd.profiling.enabled", 0), priority(caller)]
        if not caller:
            clauses += kept_by_sampling_rule()
        elif caller.style == "w3c":
            clauses += [tag("_dd.p.dm", "-0"), tag("_dd.parent_id", "0000000000000000")]
        return clauses

    return Tracer("error.stack",
                  fixed_fields(*V05_FIELDS, "meta_struct", "span_links"),
                  root, lambda caller: [ENV], [metric("_dd.top_level", 1)],
                  {"first-finished": [tag("_dd.tags.process", process_tags)]})


def dd_trace_go(process_tags: str) -> Tracer:
    def root(caller):
        clauses = [tag("_dd.p.tid", "<trace-id-high>"), tag("_dd.tags.process", process_tags),
                   metric("_dd.profiling.enabled", 0)]
        if not caller:
            clauses += kept_by_sampling_rule()
        return clauses

    return Tracer("error.handling_stack",
                  fixed_fields(*V05_FIELDS, "meta_struct"),
                  root, lambda caller: [ENV, *process_identity("go"), priority(caller)],
                  [metric("_dd.top_level", 1), metric("_dd.trace_span_attribute_schema", 0)], {})


# -- applications (corpus/datadog/shape/<app>.scm) ----------------------------

HURL = "hurl/8.0.1"


def http_server(method, route, status):
    return [tag("span.kind", "server"), tag("http.method", method), tag("http.route", route),
            tag("http.status_code", str(status)), tag("http.useragent", HURL)]


@dataclass
class Rendered:
    """A span rendered with a builder: its source and the node it evaluates."""
    node: Node
    text: str


@dataclass
class App:
    name: str
    library: str
    tracer: Callable[[str], Tracer]
    tracer_text: Callable[[str], str]
    builders: dict  # span name -> render function(span, ctx) -> Rendered | None


# ---------------------------------------------------------------------------
# Rendering


class Context:
    def __init__(self, app: App, tracer: Tracer, scenario: str):
        self.app, self.tracer, self.scenario = app, tracer, scenario
        self.caller: Caller | None = None


def same(expected: Span, actual: Span) -> bool:
    return expected.key() == actual.key()


def indent(text: str, depth: int) -> str:
    return "\n".join(("  " * depth + line) if line else line for line in text.split("\n"))


def call(head: str, args: list[str], body: list[str]) -> str:
    """Formats a builder call: arguments on the first line, clauses below."""
    first = "(" + " ".join([head, *args])
    if not body:
        return first + ")"
    lines = [first]
    for item in body:
        lines.append(indent(item, 1))
    return "\n".join(lines) + ")"


def leftovers(expected: Span, actual: Span) -> list[Clause] | None:
    """Clauses that turn a builder's span into the observed span, if local."""
    if expected.name != actual.name or expected.resource != actual.resource:
        return None
    clauses: list[Clause] = []
    if expected.service != actual.service:
        clauses.append(service(actual.service))
    if expected.type != actual.type:
        clauses.append(span_type(actual.type))
    for key, value in expected.meta.items():
        if key not in actual.meta:
            clauses.append(untag(key))
    for key, value in actual.meta.items():
        if expected.meta.get(key) != value:
            clauses.append(tag(key, value))
    for key in expected.metrics:
        if key not in actual.metrics:
            clauses.append(unmetric(key))
    for key, value in actual.metrics.items():
        if key not in expected.metrics or expected.metrics[key] != value:
            clauses.append(metric(key, value))
    return clauses


def child_order(span: Span) -> tuple:
    return (span.name, span.resource, span.key())


def render_children(ctx: Context, spans: list[Span], parent_service: str) -> list[Rendered]:
    """Renders sibling spans, folding identical siblings into (times n ...)."""
    ordered = sorted(spans, key=child_order)
    groups: list[tuple[Span, int]] = []
    for child in ordered:
        if groups and same(groups[-1][0], child):
            groups[-1] = (child, groups[-1][1] + 1)
        else:
            groups.append((child, 1))
    result = []
    for child, count in groups:
        rendered = render_span(ctx, child, parent_service)
        if count == 1:
            result.append(rendered)
        else:
            result.append(Rendered(Node("", "", [rendered.node] * count),
                                   call("times", [str(count)], [rendered.text])))
    return result


def flatten_nodes(items: list[Rendered]) -> list[Node]:
    nodes: list[Node] = []
    for item in items:
        if item.node.name == "" and item.node.resource == "":
            nodes.extend(item.node.clauses)
        else:
            nodes.append(item.node)
    return nodes


def render_span(ctx: Context, span: Span, parent_service: str | None) -> Rendered:
    builder = ctx.app.builders.get(span.name)
    if builder:
        rendered = builder(ctx, span, parent_service)
        if rendered:
            return rendered
    return render_generic(ctx, span, parent_service)


def exception_clauses(ctx: Context, span: Span) -> list[Clause]:
    stack = ctx.tracer.exception_stack
    if span.error == 1 and {"error.type", "error.message", stack} <= span.meta.keys():
        return [raised(span.meta["error.type"], span.meta["error.message"])]
    return []


def mark_clauses(ctx: Context, span: Span) -> list[Clause]:
    found = []
    for name, clauses in ctx.tracer.marks.items():
        if all(clause.kind == "tag" and span.meta.get(clause.args[0]) == clause.args[1] for clause in clauses):
            found.append(mark(name, name))
    return found


def finish(ctx: Context, span: Span, parent_service: str | None, head: str, args: list[str],
           hidden: list, params: list[Clause], children: list[Rendered],
           build: Callable[[list, list], Node] | None = None) -> Rendered | None:
    """Completes a builder rendering with exact leftovers, or gives up."""
    extras: list[Clause] = []
    if parent_service is None and ctx.caller:
        extras.append(Clause("caller", (ctx.caller,), ctx.caller.text))
    extras += exception_clauses(ctx, span) + mark_clauses(ctx, span)
    make = build or (lambda clauses, nodes: Node(span.name, span.resource, clauses + nodes))
    nodes = flatten_nodes(children)
    caller = ctx.caller
    evaluated = evaluate_span(ctx.tracer, make(hidden + params + extras, nodes), parent_service, caller)
    fixes = leftovers(evaluated, span)
    if fixes is None:
        return None
    node = make(hidden + params + extras + fixes, nodes)
    if not same(evaluate_span(ctx.tracer, node, parent_service, caller), span):
        return None
    lines = []
    inline = " ".join(clause.text for clause in params)
    if params and len(inline) <= 96:
        lines.append(inline)
    else:
        lines += [clause.text for clause in params]
    lines += [clause.text for clause in extras + fixes if clause.text]
    lines += [child.text for child in children]
    return Rendered(node, call(head, args, lines))


def render_generic(ctx: Context, span: Span, parent_service: str | None) -> Rendered:
    params: list[Clause] = []
    if span.service != APP_SERVICE:
        params.append(service(span.service))
    if span.type:
        params.append(span_type(span.type))
    children = render_children(ctx, span.children, span.service)
    rendered = finish(ctx, span, parent_service, "span", [q(span.name), q(span.resource)], [], params, children)
    if rendered is None:
        raise ValueError(f"cannot render span {span.name} {span.resource}")
    return rendered


def render_trace(ctx: Context, roots: list[Span]) -> str:
    rendered = []
    for root in sorted(roots, key=child_order):
        ctx.caller = caller_for(ctx, root)
        rendered.append(render_span(ctx, root, None).text)
    ctx.caller = None
    return call("trace", [], rendered)


def caller_for(ctx: Context, root: Span) -> Caller | None:
    if root.parent_kind != "remote" or root.remote is None:
        return None
    parent_id, trace_id, high = root.remote
    priority_value = root.metrics.get("_sampling_priority_v1", 1)
    header = root.meta.get("traceparent")
    if header is None and ctx.scenario == "propagation":
        header = f"00-{high}{int(trace_id):016x}-{int(parent_id):016x}-01"
    if header is not None:
        candidate = traceparent(header)
        if (candidate.trace_id, candidate.parent_id, candidate.trace_id_high) == (trace_id, parent_id, high):
            return candidate
    return datadog_headers(trace_id, parent_id, priority_value if isinstance(priority_value, int) else 1, high)


def trace_order(roots: list[Span]) -> tuple:
    root = min(roots, key=child_order)
    return (root.meta.get("http.route", ""), root.meta.get("http.method", ""), root.resource,
            root.meta.get("http.status_code", ""), root.meta.get("http.url", ""))


def render_shape(app: App, wire: str, profile: str, scenario: str,
                 groups: list[tuple[int, list[Span]]]) -> str:
    tracer = app.tracer(wire)
    ctx = Context(app, tracer, scenario)
    traces: list[tuple[tuple, str, int]] = []
    for count, roots in groups:
        traces.append((trace_order(roots), render_trace(ctx, roots), count))
    merged: dict[str, tuple[tuple, int]] = {}
    for order, text, count in traces:
        previous = merged.get(text)
        merged[text] = (order, (previous[1] if previous else 0) + count)
    body = []
    for text, (order, count) in sorted(merged.items(), key=lambda item: (item[1][0], item[0])):
        body.append(text if count == 1 else call("repeat", [str(count)], [text]))
    shape = call("traces", [app.tracer_text(wire)], body)
    return (
        f"; The native Datadog traces of the {scenario} scenario, reviewed for {profile}.\n"
        f"; Builders: corpus/datadog/shape/{app.name}.scm; rendered by tools/datadog_shapes.py.\n"
        f"(define-library (datadog realworld shape {profile} {scenario})\n"
        "  (export scenario-shape)\n"
        f"  (import (scheme base) (datadog trace-shape) ({app.library}))\n"
        "  (begin\n\n"
        f"(define scenario-shape\n{indent(shape, 1)})\n"
        "  ))\n"
    )


# ---------------------------------------------------------------------------
# Applications (corpus/datadog/shape/<application>.scm)


def http_params(ctx: Context, span: Span, url_prefix: str) -> tuple[list[str], list[Clause]] | None:
    method, route, status = (span.meta.get(key) for key in ("http.method", "http.route", "http.status_code"))
    if not (method and route and status and status.isdigit()):
        return None
    params = []
    url = span.meta.get("http.url", "")
    if url.startswith(url_prefix):
        params.append(tag("http.url", url, f"(url {q(url[len(url_prefix):])})"))
    agent = span.meta.get("http.useragent")
    if agent is not None and agent != HURL:
        params.append(tag("http.useragent", agent, f"(user-agent {q(agent)})"))
    return [q(method), q(route), status], params


def request_base(span: Span) -> list[Clause]:
    return [span_type("web"), *http_server(span.meta["http.method"], span.meta["http.route"], span.meta["http.status_code"])]


# -- aiohttp ------------------------------------------------------------------

AIOHTTP_PROCESS = "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true"


def aiohttp_request(ctx, span, parent):
    parsed = http_params(ctx, span, "http://<endpoint>")
    if not parsed:
        return None
    args, params = parsed
    hidden = [*request_base(span), tag("_dd.svc_src", "m"), tag("component", "aiohttp"), VERSION,
              metric("_dd.measured", 1)]
    method, route = span.meta["http.method"], span.meta["http.route"]
    build = lambda clauses, nodes: Node("aiohttp.request", f"{method} {route}", clauses + nodes)
    return finish(ctx, span, parent, "aiohttp-request", args, hidden, params,
                  render_children(ctx, span.children, span.service), build)


def sqlalchemy(ctx, span, parent):
    params = []
    if "db.row_count" in span.metrics:
        params.append(metric("db.row_count", span.metrics["db.row_count"], f"(rows {lit(span.metrics['db.row_count'])})"))
    hidden = [service("sqlite"), span_type("sql"), tag("_dd.svc_src", "sqlalchemy"), tag("component", "sqlalchemy"),
              tag("span.kind", "client"), tag("sql.db", "<fixture>/realworld.sqlite3"), VERSION,
              metric("_dd.measured", 1)]
    return finish(ctx, span, parent, "sqlalchemy", [q(span.resource)], hidden, params,
                  render_children(ctx, span.children, span.service))


AIOHTTP = App("aiohttp", "datadog shape aiohttp",
              lambda wire: dd_trace_py(wire, AIOHTTP_PROCESS), lambda wire: f"(aiohttp-app {q(wire)})",
              {"aiohttp.request": aiohttp_request, "sqlite.query": sqlalchemy})


# -- Django -------------------------------------------------------------------

DJANGO_PROCESS = AIOHTTP_PROCESS
DJANGO_INTERNAL = [tag("_dd.svc_src", "m"), tag("component", "django"), VERSION]
# settings.MIDDLEWARE, outermost first, with the hooks each one implements.
DJANGO_MIDDLEWARE = [
    ("django.middleware.security.SecurityMiddleware", ["process_request", "process_response"]),
    ("django.contrib.sessions.middleware.SessionMiddleware", ["process_request", "process_response"]),
    ("django.middleware.common.CommonMiddleware", ["process_request", "process_response"]),
    ("django.middleware.csrf.CsrfViewMiddleware", ["process_request", "process_response"]),
    ("django.contrib.auth.middleware.AuthenticationMiddleware", ["process_request"]),
    ("django.contrib.messages.middleware.MessageMiddleware", ["process_request", "process_response"]),
    ("django.middleware.clickjacking.XFrameOptionsMiddleware", ["process_response"]),
    ("corsheaders.middleware.CorsMiddleware", []),
    ("django.middleware.common.CommonMiddleware", ["process_request", "process_response"]),
]
DJANGO_VIEW_HOOKS = ["django.middleware.csrf.CsrfViewMiddleware.process_view"]


def django_span(name, resource, children=()):
    return Node(name, resource, [*DJANGO_INTERNAL, *children])


def django_stack(view: Node) -> Node:
    inner = [django_span("django.middleware", hook) for hook in DJANGO_VIEW_HOOKS] + [view]
    for middleware, hooks in reversed(DJANGO_MIDDLEWARE):
        inner = [django_span("django.middleware", f"{middleware}.__call__",
                             [*[django_span("django.middleware", f"{middleware}.{hook}") for hook in hooks], *inner])]
    return inner[0]


def find_view(span: Span) -> Span | None:
    found = [child for child in span.children if child.name == "django.view"]
    if len(found) == 1:
        return found[0]
    for child in span.children:
        result = find_view(child)
        if result:
            return result
    return None


def django_request(ctx, span, parent):
    parsed = http_params(ctx, span, "http://<endpoint>")
    view = find_view(span)
    if not parsed or not view or view.resource != "ninja.operation._sync_view":
        return None
    args, params = parsed
    if "django.view" in span.meta:
        params.append(tag("django.view", span.meta["django.view"], f"(view {q(span.meta['django.view'])})"))
    if span.meta.get("django.user.is_authenticated") == "True" and "django.user.id" in span.meta:
        user_id, user_name = span.meta["django.user.id"], span.meta.get("django.user.name", "")
        params.append(Clause("bundle", (), f"(user {q(user_id)} {q(user_name)})"))
        user_clauses = [tag("django.user.id", user_id), tag("django.user.is_authenticated", "True"),
                        tag("django.user.name", user_name), tag("usr.id", user_id)]
    else:
        user_clauses = []
    hidden = [*request_base(span), tag("_dd.svc_src", "m"), tag("component", "django"), VERSION,
              tag("django.app", "ninja"), tag("django.namespace", "api-1.0.0"),
              tag("django.request.class", "django.core.handlers.wsgi.WSGIRequest"),
              tag("django.response.class", "django.http.response.HttpResponse"),
              tag("django.user.is_authenticated", "False"), metric("_dd.measured", 1)]
    method, route = span.meta["http.method"], span.meta["http.route"]
    children = render_children(ctx, view.children, view.service)

    def build(clauses, nodes):
        expanded = []
        for clause in clauses:
            if clause.kind == "bundle":
                expanded += user_clauses
            else:
                expanded.append(clause)
        view_node = django_span("django.view", "ninja.operation._sync_view", nodes)
        return Node("django.request", f"{method} {route}", expanded + [django_stack(view_node)])

    return finish(ctx, span, parent, "django-request", args, hidden, params, children, build)


def django_sqlite(ctx, span, parent):
    params = []
    rows = span.metrics.get("db.row_count")
    if rows is not None and rows != -1:
        params.append(metric("db.row_count", rows, f"(rows {lit(rows)})"))
    hidden = [service("sqlite"), span_type("sql"), tag("_dd.svc_src", "sqlite"), tag("component", "sqlite"),
              tag("db.system", "sqlite"), tag("span.kind", "client"), metric("_dd.measured", 1),
              metric("db.row_count", -1)]
    return finish(ctx, span, parent, "sqlite", [q(span.resource)], hidden, params,
                  render_children(ctx, span.children, span.service))


def django_commit(ctx, span, parent):
    hidden = [service("sqlite"), tag("_dd.svc_src", "sqlite"), tag("component", "sqlite"),
              tag("db.system", "sqlite"), tag("span.kind", "client")]
    build = lambda clauses, nodes: Node("sqlite.connection.commit", "sqlite.connection.commit", clauses + nodes)
    return finish(ctx, span, parent, "sqlite-commit", [], hidden, [],
                  render_children(ctx, span.children, span.service), build)


DJANGO = App("django", "datadog shape django",
             lambda wire: dd_trace_py(wire, DJANGO_PROCESS), lambda wire: f"(django-app {q(wire)})",
             {"django.request": django_request, "sqlite.query": django_sqlite,
              "sqlite.connection.commit": django_commit})


# -- Rails --------------------------------------------------------------------

RAILS_PROCESS = "entrypoint.workdir:main,entrypoint.name:rails,entrypoint.basedir:bin,entrypoint.type:script,rails.application:realworld_rails,svc.user:true"


def rails_request(ctx, span, parent):
    parsed = http_params(ctx, span, "")
    if not parsed:
        return None
    args, params = parsed
    method, route, status = span.meta["http.method"], span.meta["http.route"], span.meta["http.status_code"]
    hidden = [*request_base(span), tag("component", "rack"), VERSION, tag("operation", "request"),
              tag("http.base_url", "http://<endpoint>"),
              tag("http.response.headers.x-request-id", "<request-id>"), metric("_dd.measured", 1)]
    if status != "204":
        hidden.append(tag("http.response.headers.content-type", "application/json; charset=utf-8"))

    def build(clauses, nodes):
        controllers = [node for node in nodes if node.name == "rails.action_controller"]
        resource = controllers[0].resource if controllers else f"{method} {status}"
        return Node("rack.request", resource, clauses + nodes)

    return finish(ctx, span, parent, "rack-request", args, hidden, params,
                  render_children(ctx, span.children, span.service), build)


def rails_controller(ctx, span, parent):
    controller, action = span.meta.get("rails.route.controller"), span.meta.get("rails.route.action")
    if not controller or not action:
        return None
    hidden = [span_type("web"), tag("component", "action_pack"), tag("operation", "controller"),
              tag("rails.route.action", action), tag("rails.route.controller", controller), VERSION,
              metric("_dd.measured", 1), metric("rails.db.runtime", "<duration-ms>"),
              metric("rails.view.runtime", "<duration-ms>")]
    params = []
    if "rails.db.runtime" not in span.metrics and "rails.view.runtime" not in span.metrics:
        params.append(Clause("bundle", (), "without-runtimes"))

    def build(clauses, nodes):
        expanded = []
        for clause in clauses:
            if clause.kind == "bundle" and clause.text == "without-runtimes":
                expanded += [unmetric("rails.db.runtime"), unmetric("rails.view.runtime")]
            else:
                expanded.append(clause)
        return Node("rails.action_controller", f"{controller}#{action}", expanded + nodes)

    return finish(ctx, span, parent, "action-controller", [q(controller), q(action)], hidden, params,
                  render_children(ctx, span.children, span.service), build)


def rails_sql(ctx, span, parent):
    params = []
    if span.meta.get("active_record.db.cached") == "true":
        params.append(tag("active_record.db.cached", "true", "cached"))
    hidden = [service("sqlite"), span_type("sql"), tag("_dd.svc_src", "active_record"),
              tag("active_record.db.name", "<fixture>/realworld.sqlite3"), tag("active_record.db.vendor", "sqlite"),
              tag("component", "active_record"), tag("db.instance", "<fixture>/realworld.sqlite3"),
              tag("operation", "sql"), tag("span.kind", "client"), VERSION]
    return finish(ctx, span, parent, "active-record", [q(span.resource)], hidden, params,
                  render_children(ctx, span.children, span.service))


def rails_instantiation(ctx, span, parent):
    class_name = span.meta.get("active_record.instantiation.class_name")
    records = span.metrics.get("active_record.instantiation.record_count")
    if class_name != span.resource or not isinstance(records, int):
        return None
    hidden = [span_type("custom"), tag("active_record.instantiation.class_name", class_name),
              tag("component", "active_record"), tag("operation", "instantiation"), VERSION,
              metric("_dd.measured", 1), metric("active_record.instantiation.record_count", records)]
    return finish(ctx, span, parent, "instantiate", [q(class_name), str(records)], hidden, [],
                  render_children(ctx, span.children, span.service))


RAILS = App("rails", "datadog shape rails",
            lambda wire: dd_trace_rb(RAILS_PROCESS), lambda wire: "rails-app",
            {"rack.request": rails_request, "rails.action_controller": rails_controller,
             "sqlite.query": rails_sql, "active_record.instantiation": rails_instantiation})


# -- Gin ----------------------------------------------------------------------

GIN_PROCESS = "entrypoint.name:realworld-gin-datadog,entrypoint.type:executable,entrypoint.workdir:state,svc.user:true"


def gin_request(ctx, span, parent):
    parsed = http_params(ctx, span, "http://<endpoint>")
    if not parsed:
        return None
    args, params = parsed
    method, route = span.meta["http.method"], span.meta["http.route"]
    hidden = [*request_base(span), tag("component", "gin-gonic/gin"), tag("http.host", "<endpoint>"), VERSION]
    build = lambda clauses, nodes: Node("http.request", f"{method} {route}", clauses + nodes)
    return finish(ctx, span, parent, "gin-request", args, hidden, params,
                  render_children(ctx, span.children, span.service), build)


GORM_DRIVER_KIND = {"query": "Query", "create": "Query", "update": "Exec", "delete": "Exec"}


def driver_node(kind: str, sql: str, clauses=()) -> Node:
    return Node("sqlite3.query", sql, [service("sqlite3.db"), span_type("sql"), tag("_dd.svc_src", "opt.sql_driver"),
                                       tag("component", "database/sql"), tag("db.system", "other_sql"),
                                       tag("span.kind", "client"), tag("sql.query_type", kind), *clauses])


def gorm(ctx, span, parent):
    operation = span.name.removeprefix("gorm.")
    drivers = [child for child in span.children if child.name == "sqlite3.query" and child.resource == span.resource]
    if not drivers:
        return None
    driver = drivers[0]
    kind = driver.meta.get("sql.query_type")
    expected_driver = evaluate_span(ctx.tracer, driver_node(kind, span.resource), "gorm.db", ctx.caller)
    if not same(expected_driver, driver):
        return None
    params = []
    if kind != GORM_DRIVER_KIND[operation]:
        params.append(Clause("gorm-driver", (kind,), f"(driver-call {q(kind)})"))
    others = list(span.children)
    others.remove(driver)
    hidden = [service("gorm.db"), span_type("sql"), tag("_dd.svc_src", "gorm.io/gorm.v1"),
              tag("component", "gorm.io/gorm.v1")]

    def build(clauses, nodes):
        chosen = next((clause.args[0] for clause in clauses if clause.kind == "gorm-driver"), GORM_DRIVER_KIND[operation])
        return Node(f"gorm.{operation}", span.resource, clauses + [driver_node(chosen, span.resource)] + nodes)

    return finish(ctx, span, parent, f"gorm-{operation}", [q(span.resource)], hidden, params,
                  render_children(ctx, others, span.service), build)


def database_sql(ctx, span, parent):
    kind = span.meta.get("sql.query_type")
    if not kind:
        return None
    args = [q(kind)] if span.resource == kind else [q(kind), q(span.resource)]
    build = lambda clauses, nodes: Node("sqlite3.query", span.resource, clauses + nodes)
    hidden = driver_node(kind, span.resource).clauses
    return finish(ctx, span, parent, "database-sql", args, hidden, [],
                  render_children(ctx, span.children, span.service), build)


GIN = App("gin", "datadog shape gin",
          lambda wire: dd_trace_go(GIN_PROCESS), lambda wire: "gin-app",
          {"http.request": gin_request, **{f"gorm.{op}": gorm for op in ("query", "create", "update", "delete")},
           "sqlite3.query": database_sql})

APPLICATIONS = {"aiohttp": AIOHTTP, "django": DJANGO, "rails": RAILS, "gin": GIN}


def profile_application(profile: str) -> tuple[App, str]:
    for name, app in APPLICATIONS.items():
        if f"-{name}-" in profile:
            wire = "v0.5" if profile.endswith("-v05") else "v0.4"
            return app, wire
    raise ValueError(f"unknown Datadog profile application in {profile}")


def render_file(profile: str, scenario: str, source: str) -> str:
    app, wire = profile_application(profile)
    return render_shape(app, wire, profile, scenario, read_candidate(source))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)
    single = commands.add_parser("render", help="render one candidate")
    single.add_argument("--profile", required=True)
    single.add_argument("--scenario", required=True)
    single.add_argument("candidate", type=Path)
    tree = commands.add_parser("render-tree", help="render <candidates>/<scenario>.scm into <shapes>/")
    tree.add_argument("--profile", required=True)
    tree.add_argument("candidates", type=Path)
    tree.add_argument("shapes", type=Path)
    args = parser.parse_args()
    if args.command == "render":
        sys.stdout.write(render_file(args.profile, args.scenario, args.candidate.read_text()))
        return
    args.shapes.mkdir(parents=True, exist_ok=True)
    for candidate in sorted(args.candidates.glob("*.scm")):
        (args.shapes / candidate.name).write_text(render_file(args.profile, candidate.stem, candidate.read_text()))


if __name__ == "__main__":
    main()
