(define expected-span-buckets
  (append (http-contract-buckets (expected-http-requests-for scenario-name)
                                 server-scope
                                 render-server-span-name)
          (implementation-buckets-for scenario-name)))

(otel-validate-exact expected-resource-attributes
                     expected-scopes
                     expected-metric-scopes
                     expected-metric-descriptors
                     expected-metric-aggregation
                     expected-log-scopes
                     expected-log-severity-required
                     (event-policy-for scenario-name)
                     expected-span-flags
                     expected-span-buckets
                     (read))
