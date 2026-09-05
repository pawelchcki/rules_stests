# Drive non-ASCII text through the two attributes every HTTP instrumentation
# records: the request target and the User-Agent. The profile is not registered,
# so the response is a 404 from the application rather than from routing.
GET {{host}}/api/profiles/ünïcøde_{{uid}}
User-Agent: rules-stests/ünïcødé
HTTP 404
