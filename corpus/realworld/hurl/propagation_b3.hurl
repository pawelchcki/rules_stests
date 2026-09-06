# The same three propagated tags requests as the `propagation` scenario, but
# carrying B3 multi headers instead of a W3C traceparent. Only a deployment
# configured for the B3 propagator will turn these into a remote parent, so the
# scenario belongs to the variant that sets OTEL_PROPAGATORS.
#
# The registration that opens the scenario propagates nothing, so the capture
# keeps a root span and the database instrumentation scope.
POST {{host}}/api/users
{
  "user": {
    "username": "b3_{{uid}}",
    "email": "b3_{{uid}}@test.com",
    "password": "password123"
  }
}
HTTP 201

GET {{host}}/api/tags
X-B3-TraceId: 4bf92f3577b34da6a3ce929d0e0e4736
X-B3-SpanId: 00f067aa0ba902b7
X-B3-Sampled: 1
HTTP 200
[Asserts]
jsonpath "$.tags" isList

GET {{host}}/api/tags
X-B3-TraceId: 8c1e0a5b6d2f47398a4b0c7e1d5f3a92
X-B3-SpanId: 00f067aa0ba902b7
X-B3-Sampled: 1
HTTP 200
[Asserts]
jsonpath "$.tags" isList

GET {{host}}/api/tags
X-B3-TraceId: b3f7d21c9e6a48059c7d2e8f4a1b6035
X-B3-SpanId: 00f067aa0ba902b7
X-B3-Sampled: 1
HTTP 200
[Asserts]
jsonpath "$.tags" isList
