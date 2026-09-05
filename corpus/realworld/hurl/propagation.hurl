# Continue three distinct external traces through the public tags endpoint.
#
# Each tags request carries a W3C traceparent whose trace id differs but whose
# parent span id is the same, so the recorded shape can pin the parent span id
# while every request still lands in a trace of its own. No tracestate is sent:
# the portable contracts pin trace-state to the empty string.
#
# The registration that opens the scenario sends no traceparent. It keeps a
# root span and the database instrumentation scope in the capture, so the
# propagated requests are the only thing that sets this scenario apart.
POST {{host}}/api/users
{
  "user": {
    "username": "prop_{{uid}}",
    "email": "prop_{{uid}}@test.com",
    "password": "password123"
  }
}
HTTP 201

GET {{host}}/api/tags
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
HTTP 200
[Asserts]
jsonpath "$.tags" isList

GET {{host}}/api/tags
traceparent: 00-8c1e0a5b6d2f47398a4b0c7e1d5f3a92-00f067aa0ba902b7-01
HTTP 200
[Asserts]
jsonpath "$.tags" isList

GET {{host}}/api/tags
traceparent: 00-b3f7d21c9e6a48059c7d2e8f4a1b6035-00f067aa0ba902b7-01
HTTP 200
[Asserts]
jsonpath "$.tags" isList
