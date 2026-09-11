Datadog profiles use an independent feature catalog (`features.json` and its
Scheme bindings in `catalog.scm`) and executable proof table (`proofs.scm`).
They do not claim OpenTelemetry specification compliance. Manifests and proof
receipts identify family `datadog` and the selected intake wire version.

The two v0.5 application profiles cover the 15 baseline RealWorld scenarios and
`propagation_datadog`. Each application also has a v0.4 MessagePack `tags`
profile. Native Datadog-header propagation deliberately uses unsigned trace IDs
above the signed 64-bit range; the corresponding high bits travel in `_dd.p.tid`.
The W3C scenario continues those same 128-bit identities through `traceparent`.

`capture/shapes.scm` checks native span fields, lossless decimal identifiers,
completion, semantic validity, intake headers and chunk counts, HTTP error
classification, database ancestry reaching the HTTP request, and complete
exception metadata when an exception is recorded. Database classification
includes `sqlite.connection.commit`, whose native type is empty.
`profile.scm` additionally checks the profile's intake version, declared
language/tracer version, and service name,
the scenario's HTTP request multiplicities, and reviewed native trace trees.
For aiohttp, SQLAlchemy instrumentation records database operations in the
request context before aiosqlite dispatches to its private worker thread. The
underlying SQLite integration is disabled there to avoid detached duplicate
traces. Django uses the native SQLite integration.

HTTP responses below 500 do not mark the server span as an error under the
configured default policy; database or view spans may still record exceptions.

Exact expectations live separately under `realworld/shape/<profile>/<scenario>`.
The sink generates their candidate data from native Datadog spans, retaining
every native field name, service, operation name, resource, type, error
classification, parentage, children, and complete tag and metric maps. Duplicate children and grouped root
counts preserve multiplicities. Remote roots retain caller IDs. Variable local
IDs and timing values are checked by the capture assertions rather than frozen
in the tree; SQL resource text is matched exactly, including fixed literals and query
parameter placeholders. Only service identity, loopback endpoint ports,
generated workload suffixes, temporary database paths, validated runtime and
process identifiers, trace high bits, and structurally valid exception stacks
use explicit policies. Changes to those policies require reviewing the resulting
expectations. Candidate generation alone does not make a topology reviewed.

`datadog_realworld_profile(reference_profile = ...)` lets an external profile
reuse a published expectation set without copying it. The analysis rule rejects
replacement scenarios/shapes and wire-version changes; the compiler rejects a
different application, signals, or proof contract and requires every reference
scenario shape. Candidate implementation identity remains in its own plan and
receipt digest.

Validation failures use `DATADOG-CONTRACT-V2`; successful feature checks emit
`DATADOG-PROOF-V2`. Both markers are specific to this family. The driver binds
receipt parsing to the selected manifest family and never treats an OTLP proof
marker as Datadog evidence.
