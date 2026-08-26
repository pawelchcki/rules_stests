(define expected-span-buckets
  (http-contract-buckets (expected-http-requests-for scenario-name)
                         server-scope
                         render-server-span-name))

(otel-validate-contract expected-resource-attributes
                        expected-scopes
                        (event-policy-for scenario-name)
                        expected-span-buckets
                        (read))
