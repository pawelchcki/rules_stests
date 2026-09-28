# The Datadog contract

Datadog profiles use their own feature catalog and proof tables; they make no
OpenTelemetry claims. Manifests and receipts identify family `datadog` and the
intake wire version.

## Where things are

| Path | What it says |
| --- | --- |
| `features.json`, `catalog.scm` | Every feature id with its theme, a one-line description, and the binding profiles claim it with |
| `proofs/<theme>.scm` | Which capture assertion proves each feature |
| `capture/<theme>.scm` | The assertions: predicates over the decoded capture (`capture/base.scm` has the readers) |
| `capture/shapes.scm` | The registry naming every assertion, by theme |
| `trace-shape.scm` | The language reviewed trace shapes are written in, and the tracer rules it applies |
| `trace-shape/match.scm` | Exact, order-insensitive comparison of a shape with a capture, with explanations |
| `shape/tracers.scm` | What dd-trace-py, dd-trace-rb, and dd-trace-go add to spans on their own |
| `shape/<application>.scm` | The span builders for each application's integrations (aiohttp, Django, Rails, Falcon, Gin) |
| `realworld/profile/<profile>.scm` | A profile: identity plus the features it claims, by theme |
| `realworld/shape/<profile>/<scenario>.scm` | The reviewed native traces of one scenario |

Themes are the same everywhere: intake, traces, service, sampling,
propagation, http, database, errors, and coverage.

## Reading a shape

A shape lists the traces a scenario produces, one request per trace:

```scheme
(traces (django-app "v0.4")
  (trace
    (django-request "GET" "api/tags" 200
      (url "/api/tags") (view "api-1.0.0:list_tags")
      (continues (traceparent "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"))
      (sqlite "PRAGMA foreign_keys = ON")
      (sqlite "SELECT \"articles_tag\".\"id\", \"articles_tag\".\"name\" FROM \"articles_tag\""))))
```

- The first line of each builder is what Datadog shows: `django-request`
  produces a `django.request` span with resource `GET api/tags` and status 200.
  Clauses below it add what varies per request (URL, view, user) and the child
  spans.
- `shape/django.scm` defines what every `django.request`, middleware, view,
  and `sqlite` span carries: tags, metrics, service, type, and where the
  children go (inside the view, inside the middleware stack).
- `shape/tracers.scm` states the tracer's own behavior once:
  - the sampling decision on each trace root
  - `_dd.top_level` on service-entry spans
  - `_dd.base_service` on spans reported under an integration's service
  - `env`, and process identity
  - which native fields the wire encoding writes
- `(continues ...)` marks a request that continued an upstream caller's trace,
  written as the headers the caller sent. The span's parent is remote and
  carries the caller's ids and sampling priority.
- `(times n ...)` repeats a sibling span.
- `(repeat n (trace ...))` repeats a whole trace.
- `(raised type message)` records an exception.
- `(tag ...)`, `(untag ...)`, `(metric ...)`, and `(unmetric ...)` adjust one
  span.

Shapes are exact. `trace-shape/match.scm` requires every native field name,
service, name, type, resource, parent kind, error flag, tag, metric, edge, and
multiplicity to agree. Only order is ignored: the order of traces, siblings,
tags, metrics, and native field names. A difference is reported at its path,
for example:

```
first difference at django.request GET api/tags > django.middleware ... > sqlite.query SELECT ...:
tag db.system expected "sqlite" but was "sqlite3"
```

The sink replaces values that legitimately vary between runs with explicit
placeholders:

| Placeholder | Stands for |
| --- | --- |
| `<service>` | The trace's HTTP service |
| `<endpoint>` | The loopback host and port |
| `<workload>` | The generated suffix of workload names |
| `<fixture>` | The temporary database directory |
| `<runtime-id>`, `<process-id>`, `<request-id>` | Validated per-run identifiers |
| `<trace-id-high>` | Validated generated high trace-id bits |
| `<validated-stack>` | A structurally validated exception stack |
| `<duration-ms>` | Rails runtime measurements |

SQL text, routes, URLs, and every other value are compared literally.

## Features by theme

`features.json` describes each feature. The profiles claim the features their
tracer satisfies and say why they skip the others:

| Feature | aiohttp | Django | Rails | Falcon | Gin |
| --- | :-: | :-: | :-: | :-: | :-: |
| intake: headers and counts, library headers, semantic validity, chunk coherence | ✓ | ✓ | ✓ | ✓ | ✓ |
| traces: native fields, unsigned ids, completion, root span, 128-bit trace ids | ✓ | ✓ | ✓ | ✓ | ✓ |
| service: service identity, base service, unified service tags, process identity | ✓ | ✓ | ✓ | ✓ | ✓ |
| service: version only on the configured service | – | ✓ | – | – | ✓ |
| sampling: priority, decision maker, rule keep | ✓ | ✓ | ✓ | ✓ | ✓ |
| propagation: W3C and Datadog parents, caller's sampling priority kept | ✓ | ✓ | ✓ | ✓ | ✓ |
| http: classification, server tags, route matches URL | ✓ | ✓ | ✓ | ✓ | ✓ |
| http: absolute `http.url` | ✓ | ✓ | – | – | ✓ |
| database: spans under the request | ✓ | ✓ | ✓ | ✓ | ✓ |
| database: `span.kind` client | ✓ | ✓ | ✓ | ✓ | – |
| database: `db.system` | – | ✓ | – | ✓ | – |
| errors: exception metadata, errors explained | ✓ | ✓ | ✓ | ✓ | ✓ |
| coverage: field policies | ✓ | ✓ | ✓ | ✓ | ✓ |

The gaps, as observed:

- **aiohttp** (`version` scoping, `db.system`): SQLAlchemy spans report under
  `sqlite` but carry `version`, and they name the database in `sql.db` rather
  than `db.system`.
- **Rails and Falcon** (`version` scoping, absolute URL; Rails also `db.system`):
  - Active Record and Sequel spans also carry `version`.
  - Rack records a path in `http.url`, with the origin in `http.base_url`
    (system-tests `Test_Meta`, bug APMAPI-922).
  - Rails names the database in `active_record.db.vendor`; Sequel sets `db.system`.
- **Gin** (`span.kind` client, `db.system`): GORM operation spans carry
  neither; their database/sql child spans carry both.

Where a check mirrors an assertion in
[DataDog/system-tests](https://github.com/DataDog/system-tests/tree/ea8a5976064509df0a5232e314b22e7e90ca4d40/tests),
the predicate names the upstream test.

Native Datadog-header propagation deliberately uses unsigned trace ids above
the signed 64-bit range; the high bits travel in `_dd.p.tid`. The W3C scenario
continues the same 128-bit identities through `traceparent`.

## Reviewing a new shape

The driver's candidate mode writes the sink's canonical topology for each
scenario to `test.outputs/datadog/shape/<profile>/<scenario>.scm`. Render the
candidates in the vocabulary, review them, and check them in:

```bash
bazel run //tools:datadog_shapes -- render-tree --profile <profile> \
  <candidate-directory> "$PWD/corpus/datadog/realworld/shape/<profile>"
```

The renderer writes a shape only when its model evaluates it back to exactly
the candidate. `//tools:datadog_shapes_test` checks that the model and the
Scheme vocabulary agree. Spans outside the vocabulary are written with the
generic `span` builder. Candidate generation alone does not make a topology
reviewed.

## Reference profiles

`datadog_realworld_profile(reference_profile = ...)` lets an external profile
reuse a published expectation set without copying it:

- The analysis rule rejects replacement scenarios or shapes, and wire-version
  changes.
- The compiler rejects a different application, signals, or proof contract,
  and requires every reference scenario shape.
- The candidate's implementation identity stays in its own plan and receipt
  digest.

## Markers

Validation failures use `DATADOG-CONTRACT-V2`; successful feature checks emit
`DATADOG-PROOF-V2`. Both markers are specific to this family. The driver binds
receipt parsing to the selected manifest family and never treats an OTLP proof
marker as Datadog evidence.
