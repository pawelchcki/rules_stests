(define expected-span-buckets
  (append (http-contract-buckets (expected-http-requests-for scenario-name)
                                 server-scope
                                 render-server-span-name)
          (implementation-buckets-for scenario-name)))

(otel-validate-exact expected-resource-attributes
                     expected-scopes
                     event-policy
                     expected-span-buckets
                     (read))
