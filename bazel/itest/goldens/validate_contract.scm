(define expected-span-buckets
  (http-contract-buckets expected-http-requests
                         server-scope
                         render-server-span-name))

(otel-validate-contract expected-resource-attributes
                        expected-scopes
                        event-policy
                        expected-span-buckets
                        (read))
