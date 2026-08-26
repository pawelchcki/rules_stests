(define expected-span-buckets
  (http-contract-buckets (expected-http-requests-for scenario-name)
                         server-scope
                         render-server-span-name))

(define capture (read))

(otel-validate-exact expected-resource-attributes
                     expected-resource-schema-url
                     expected-scopes
                     expected-metric-scopes
                     expected-metric-descriptors
                     expected-metric-aggregation
                     expected-metric-point-schemas
                     expected-log-scopes
                     expected-log-policy
                     (event-policy-for scenario-name)
                     expected-span-flags
                     expected-trace-state
                     expected-error-status-message-policy
                     expected-span-buckets
                     capture)

(otel-validate-trace-shapes expected-trace-shapes capture)
