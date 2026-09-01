(define-library (realworld shape ruby-rails-auto-v0-1-0 tags)
  (export scenario-shape)
  (import (scheme base) (otel trace-shape))
  (begin
(define scenario-shape
  (traces
    (trace (coverage 'complete)
      (unordered
        (span (scope "OpenTelemetry::Instrumentation::Rack") (kind 'server) (status 'unset) (name (exact "DELETE /api/articles/:slug")) (http-status 204)
          (children (unordered
            (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "Article query")) (http-status 'absent))
            (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "Article#destroy!")) (http-status 'absent)
              (children (unordered
                (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "Article#destroy")) (http-status 'absent)
                  (children (unordered
                    (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "ActiveRecord.transaction")) (http-status 'absent)
                      (children (unordered
                        (repeat 2 (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "ArticleTag#destroy!")) (http-status 'absent)
                            (children (unordered
                              (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "ArticleTag#destroy")) (http-status 'absent)))))))))
                    (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "Comment query")) (http-status 'absent))
                    (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "Favorite query")) (http-status 'absent))))))))
            (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "ArticleTag query")) (http-status 'absent))
            (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "Tag query")) (http-status 'absent))
            (repeat 2 (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "User query")) (http-status 'absent))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "OpenTelemetry::Instrumentation::Rack") (kind 'server) (status 'unset) (name (exact "GET /api/tags")) (http-status 200))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "OpenTelemetry::Instrumentation::Rack") (kind 'server) (status 'unset) (name (exact "POST /api/articles")) (http-status 201)
          (children (unordered
            (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "ActiveRecord.transaction")) (http-status 'absent)
              (children (unordered
                (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "ActiveRecord.transaction")) (http-status 'absent)
                  (children (unordered
                    (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "ActiveRecord.transaction")) (http-status 'absent)
                      (children (unordered
                        (repeat 2 (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "ArticleTag#save!")) (http-status 'absent)))))))))
                (repeat 2 (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "ActiveRecord.transaction")) (http-status 'absent)
                    (children (unordered
                      (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "Tag.create!")) (http-status 'absent)
                        (children (unordered
                          (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "Tag#save!")) (http-status 'absent)))))))))
                (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "Article#save!")) (http-status 'absent))
                (repeat 3 (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "Tag query")) (http-status 'absent))))))
            (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "Article#reload")) (http-status 'absent)
              (children (unordered
                (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "Article query")) (http-status 'absent)))))
            (repeat 2 (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "User query")) (http-status 'absent))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "OpenTelemetry::Instrumentation::Rack") (kind 'server) (status 'unset) (name (exact "POST /api/users")) (http-status 201)
          (children (unordered
            (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "User#save")) (http-status 'absent)))))))))
  ))
