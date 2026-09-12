(define-library (datadog realworld shape go-gin-datadog-v2-10-1-v04 auth)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape))
  (begin
(define scenario-shape
  '(
    (
      (count 8)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "http.request")
            (type "web")
            (resource "GET /api/user")
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
                ("http.route" "/api/user")
                ("http.status_code" "200")
                ("http.url" "http://<endpoint>/api/user")
                ("http.useragent" "hurl/8.0.1")
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
                  (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "gorm.io/gorm.v1")
                      ("component" "gorm.io/gorm.v1")
                      ("env" "test")
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
                        (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
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
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "gorm.db")
                  (name "gorm.query")
                  (type "sql")
                  (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "gorm.io/gorm.v1")
                      ("component" "gorm.io/gorm.v1")
                      ("env" "test")
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
                        (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
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
                          ())))))))))))
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
            (resource "POST /api/users")
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
                ("http.method" "POST")
                ("http.route" "/api/users")
                ("http.status_code" "201")
                ("http.url" "http://<endpoint>/api/users")
                ("http.useragent" "hurl/8.0.1")
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
                  (name "gorm.create")
                  (type "sql")
                  (resource "INSERT INTO `user_models` (`username`,`email`,`bio`,`image`,`password`) VALUES (?,?,?,?,?) RETURNING `id`")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "gorm.io/gorm.v1")
                      ("component" "gorm.io/gorm.v1")
                      ("env" "test")
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
                        (resource "Commit")
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
                            ("sql.query_type" "Commit")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)
                            ("_dd.trace_span_attribute_schema" 0.0)
                            ("_sampling_priority_v1" 2.0)
                            ("process_id" "<process-id>")))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                        (service "sqlite3.db")
                        (name "sqlite3.query")
                        (type "sql")
                        (resource "INSERT INTO `user_models` (`username`,`email`,`bio`,`image`,`password`) VALUES (?,?,?,?,?) RETURNING `id`")
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
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "gorm.db")
                  (name "gorm.query")
                  (type "sql")
                  (resource "SELECT * FROM `user_models` WHERE `user_models`.`email` = ? ORDER BY `user_models`.`id` LIMIT 1")
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
                        (resource "SELECT * FROM `user_models` WHERE `user_models`.`email` = ? ORDER BY `user_models`.`id` LIMIT 1")
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
                          ())))))
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
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "sqlite3.db")
                  (name "sqlite3.query")
                  (type "sql")
                  (resource "Begin")
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
                      ("sql.query_type" "Begin")))
                  (metrics
                    (
                      ("_dd.top_level" 1.0)
                      ("_dd.trace_span_attribute_schema" 0.0)
                      ("_sampling_priority_v1" 2.0)
                      ("process_id" "<process-id>")))
                  (children
                    ()))))))))
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
            (resource "POST /api/users/login")
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
                ("http.method" "POST")
                ("http.route" "/api/users/login")
                ("http.status_code" "200")
                ("http.url" "http://<endpoint>/api/users/login")
                ("http.useragent" "hurl/8.0.1")
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
                  (resource "SELECT * FROM `user_models` WHERE `user_models`.`email` = ? ORDER BY `user_models`.`id` LIMIT 1")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "gorm.io/gorm.v1")
                      ("component" "gorm.io/gorm.v1")
                      ("env" "test")
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
                        (resource "SELECT * FROM `user_models` WHERE `user_models`.`email` = ? ORDER BY `user_models`.`id` LIMIT 1")
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
                          ())))))))))))
    (
      (count 5)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "http.request")
            (type "web")
            (resource "PUT /api/user")
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
                ("http.method" "PUT")
                ("http.route" "/api/user")
                ("http.status_code" "200")
                ("http.url" "http://<endpoint>/api/user")
                ("http.useragent" "hurl/8.0.1")
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
                  (resource "SELECT * FROM `user_models` WHERE `user_models`.`email` = ? ORDER BY `user_models`.`id` LIMIT 1")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "gorm.io/gorm.v1")
                      ("component" "gorm.io/gorm.v1")
                      ("env" "test")
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
                        (resource "SELECT * FROM `user_models` WHERE `user_models`.`email` = ? ORDER BY `user_models`.`id` LIMIT 1")
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
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "gorm.db")
                  (name "gorm.query")
                  (type "sql")
                  (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "gorm.io/gorm.v1")
                      ("component" "gorm.io/gorm.v1")
                      ("env" "test")
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
                        (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
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
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "gorm.db")
                  (name "gorm.query")
                  (type "sql")
                  (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "gorm.io/gorm.v1")
                      ("component" "gorm.io/gorm.v1")
                      ("env" "test")
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
                        (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
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
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "gorm.db")
                  (name "gorm.query")
                  (type "sql")
                  (resource "SELECT * FROM `user_models` WHERE `user_models`.`username` = ? ORDER BY `user_models`.`id` LIMIT 1")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "gorm.io/gorm.v1")
                      ("component" "gorm.io/gorm.v1")
                      ("env" "test")
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
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "gorm.db")
                  (name "gorm.update")
                  (type "sql")
                  (resource "UPDATE `user_models` SET `bio`=? WHERE `id` = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "gorm.io/gorm.v1")
                      ("component" "gorm.io/gorm.v1")
                      ("env" "test")
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
                        (resource "UPDATE `user_models` SET `bio`=? WHERE `id` = ?")
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
                            ("sql.query_type" "Exec")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)
                            ("_dd.trace_span_attribute_schema" 0.0)
                            ("_sampling_priority_v1" 2.0)
                            ("process_id" "<process-id>")))
                        (children
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "sqlite3.db")
                  (name "sqlite3.query")
                  (type "sql")
                  (resource "Begin")
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
                      ("sql.query_type" "Begin")))
                  (metrics
                    (
                      ("_dd.top_level" 1.0)
                      ("_dd.trace_span_attribute_schema" 0.0)
                      ("_sampling_priority_v1" 2.0)
                      ("process_id" "<process-id>")))
                  (children
                    ()))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "sqlite3.db")
                  (name "sqlite3.query")
                  (type "sql")
                  (resource "Commit")
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
                      ("sql.query_type" "Commit")))
                  (metrics
                    (
                      ("_dd.top_level" 1.0)
                      ("_dd.trace_span_attribute_schema" 0.0)
                      ("_sampling_priority_v1" 2.0)
                      ("process_id" "<process-id>")))
                  (children
                    ()))))))))
    (
      (count 4)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "http.request")
            (type "web")
            (resource "PUT /api/user")
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
                ("http.method" "PUT")
                ("http.route" "/api/user")
                ("http.status_code" "200")
                ("http.url" "http://<endpoint>/api/user")
                ("http.useragent" "hurl/8.0.1")
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
                  (resource "SELECT * FROM `user_models` WHERE `user_models`.`email` = ? ORDER BY `user_models`.`id` LIMIT 1")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "gorm.io/gorm.v1")
                      ("component" "gorm.io/gorm.v1")
                      ("env" "test")
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
                        (resource "SELECT * FROM `user_models` WHERE `user_models`.`email` = ? ORDER BY `user_models`.`id` LIMIT 1")
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
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "gorm.db")
                  (name "gorm.query")
                  (type "sql")
                  (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "gorm.io/gorm.v1")
                      ("component" "gorm.io/gorm.v1")
                      ("env" "test")
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
                        (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
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
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "gorm.db")
                  (name "gorm.query")
                  (type "sql")
                  (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "gorm.io/gorm.v1")
                      ("component" "gorm.io/gorm.v1")
                      ("env" "test")
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
                        (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
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
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "gorm.db")
                  (name "gorm.query")
                  (type "sql")
                  (resource "SELECT * FROM `user_models` WHERE `user_models`.`username` = ? ORDER BY `user_models`.`id` LIMIT 1")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "gorm.io/gorm.v1")
                      ("component" "gorm.io/gorm.v1")
                      ("env" "test")
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
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "gorm.db")
                  (name "gorm.update")
                  (type "sql")
                  (resource "UPDATE `user_models` SET `image`=? WHERE `id` = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "gorm.io/gorm.v1")
                      ("component" "gorm.io/gorm.v1")
                      ("env" "test")
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
                        (resource "UPDATE `user_models` SET `image`=? WHERE `id` = ?")
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
                            ("sql.query_type" "Exec")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)
                            ("_dd.trace_span_attribute_schema" 0.0)
                            ("_sampling_priority_v1" 2.0)
                            ("process_id" "<process-id>")))
                        (children
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "sqlite3.db")
                  (name "sqlite3.query")
                  (type "sql")
                  (resource "Begin")
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
                      ("sql.query_type" "Begin")))
                  (metrics
                    (
                      ("_dd.top_level" 1.0)
                      ("_dd.trace_span_attribute_schema" 0.0)
                      ("_sampling_priority_v1" 2.0)
                      ("process_id" "<process-id>")))
                  (children
                    ()))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "sqlite3.db")
                  (name "sqlite3.query")
                  (type "sql")
                  (resource "Commit")
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
                      ("sql.query_type" "Commit")))
                  (metrics
                    (
                      ("_dd.top_level" 1.0)
                      ("_dd.trace_span_attribute_schema" 0.0)
                      ("_sampling_priority_v1" 2.0)
                      ("process_id" "<process-id>")))
                  (children
                    ()))))))))
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
            (resource "PUT /api/user")
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
                ("http.method" "PUT")
                ("http.route" "/api/user")
                ("http.status_code" "200")
                ("http.url" "http://<endpoint>/api/user")
                ("http.useragent" "hurl/8.0.1")
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
                  (resource "SELECT * FROM `user_models` WHERE `user_models`.`email` = ? ORDER BY `user_models`.`id` LIMIT 1")
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
                        (resource "SELECT * FROM `user_models` WHERE `user_models`.`email` = ? ORDER BY `user_models`.`id` LIMIT 1")
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
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "gorm.db")
                  (name "gorm.query")
                  (type "sql")
                  (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "gorm.io/gorm.v1")
                      ("component" "gorm.io/gorm.v1")
                      ("env" "test")
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
                        (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
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
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "gorm.db")
                  (name "gorm.query")
                  (type "sql")
                  (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "gorm.io/gorm.v1")
                      ("component" "gorm.io/gorm.v1")
                      ("env" "test")
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
                        (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
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
                          ())))))
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
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "gorm.db")
                  (name "gorm.update")
                  (type "sql")
                  (resource "UPDATE `user_models` SET `email`=?,`username`=? WHERE `id` = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "gorm.io/gorm.v1")
                      ("component" "gorm.io/gorm.v1")
                      ("env" "test")
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
                        (resource "UPDATE `user_models` SET `email`=?,`username`=? WHERE `id` = ?")
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
                            ("sql.query_type" "Exec")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)
                            ("_dd.trace_span_attribute_schema" 0.0)
                            ("_sampling_priority_v1" 2.0)
                            ("process_id" "<process-id>")))
                        (children
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "sqlite3.db")
                  (name "sqlite3.query")
                  (type "sql")
                  (resource "Begin")
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
                      ("sql.query_type" "Begin")))
                  (metrics
                    (
                      ("_dd.top_level" 1.0)
                      ("_dd.trace_span_attribute_schema" 0.0)
                      ("_sampling_priority_v1" 2.0)
                      ("process_id" "<process-id>")))
                  (children
                    ()))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "sqlite3.db")
                  (name "sqlite3.query")
                  (type "sql")
                  (resource "Commit")
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
                      ("sql.query_type" "Commit")))
                  (metrics
                    (
                      ("_dd.top_level" 1.0)
                      ("_dd.trace_span_attribute_schema" 0.0)
                      ("_sampling_priority_v1" 2.0)
                      ("process_id" "<process-id>")))
                  (children
                    ()))))))))))
  ))
