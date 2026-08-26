(define expected-span-buckets
  (append (http-contract-buckets expected-http-requests
                                 server-scope
                                 render-server-span-name)
          expected-implementation-buckets))

(otel-validate-exact expected-resource-attributes
                     expected-scopes
                     event-policy
                     expected-span-buckets
                     (read))
