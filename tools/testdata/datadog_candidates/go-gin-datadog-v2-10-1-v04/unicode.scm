(define-library (datadog realworld shape go-gin-datadog-v2-10-1-v04 unicode)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape))
  (begin
(define scenario-shape
  '(
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "http.request")
            (type "web")
            (resource "GET /api/profiles/:username")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("_dd.tags.process" "entrypoint.name:realworld-gin-datadog,entrypoint.type:executable,entrypoint.workdir:state,svc.user:true")
                ("component" "gin-gonic/gin")
                ("env" "test")
                ("http.host" "<endpoint>")
                ("http.method" "GET")
                ("http.route" "/api/profiles/:username")
                ("http.status_code" "404")
                ("http.url" "http://<endpoint>/api/profiles/%C3%BCn%C3%AFc%C3%B8de_rules_stests_<workload>")
                ("http.useragent" "rules-stests/ünïcødé")
                ("language" "go")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_dd.trace_span_attribute_schema" 0.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "gorm.db")
                  (name "gorm.query")
                  (type "sql")
                  (resource "SELECT * FROM `user_models` WHERE `user_models`.`username` = ? ORDER BY `user_models`.`id` LIMIT 1")
                  (parent-kind "child")
                  (error 1)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "gorm.io/gorm.v1")
                      ("component" "gorm.io/gorm.v1")
                      ("env" "test")
                      ("error.handling_stack" "<validated-stack>")
                      ("error.message" "record not found")
                      ("error.type" "*errors.errorString")
                      ("language" "go")
                      ("runtime-id" "<runtime-id>")))
                  (metrics
                    (
                      ("_dd.top_level" 1.0)
                      ("_dd.trace_span_attribute_schema" 0.0)
                      ("_sampling_priority_v1" 2.0)
                      ("process_id" "<process-id>")))
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                        (service "sqlite3.db")
                        (name "sqlite3.query")
                        (type "sql")
                        (resource "SELECT * FROM `user_models` WHERE `user_models`.`username` = ? ORDER BY `user_models`.`id` LIMIT 1")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "opt.sql_driver")
                            ("component" "database/sql")
                            ("db.system" "other_sql")
                            ("env" "test")
                            ("language" "go")
                            ("runtime-id" "<runtime-id>")
                            ("span.kind" "client")
                            ("sql.query_type" "Query")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)
                            ("_dd.trace_span_attribute_schema" 0.0)
                            ("_sampling_priority_v1" 2.0)
                            ("process_id" "<process-id>")))
                        (children
                          ())))))))))))))
  ))
