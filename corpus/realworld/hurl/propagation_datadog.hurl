# Native decimal Datadog IDs include values above signed 64-bit precision.
# The high trace bits are propagated independently in x-datadog-tags.
POST {{host}}/api/users
{
  "user": {
    "username": "ddprop_{{uid}}",
    "email": "ddprop_{{uid}}@test.com",
    "password": "password123"
  }
}
HTTP 201

GET {{host}}/api/tags
x-datadog-trace-id: 11803532876627986230
x-datadog-parent-id: 67667974448284343
x-datadog-sampling-priority: 1
x-datadog-tags: _dd.p.tid=4bf92f3577b34da6
HTTP 200
[Asserts]
jsonpath "$.tags" isList

GET {{host}}/api/tags
x-datadog-trace-id: 9965072336285547154
x-datadog-parent-id: 67667974448284343
x-datadog-sampling-priority: 1
x-datadog-tags: _dd.p.tid=8c1e0a5b6d2f4739
HTTP 200
[Asserts]
jsonpath "$.tags" isList

GET {{host}}/api/tags
x-datadog-trace-id: 11276220234964099125
x-datadog-parent-id: 67667974448284343
x-datadog-sampling-priority: 1
x-datadog-tags: _dd.p.tid=b3f7d21c9e6a4805
HTTP 200
[Asserts]
jsonpath "$.tags" isList
