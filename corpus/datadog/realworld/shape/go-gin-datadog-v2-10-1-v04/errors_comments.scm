(define-library (datadog realworld shape go-gin-datadog-v2-10-1-v04 errors_comments)
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
            (resource "DELETE /api/articles/:slug")
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
                ("http.method" "DELETE")
                ("http.route" "/api/articles/:slug")
                ("http.status_code" "204")
                ("http.url" "http://<endpoint>/api/articles/err-comment-art-rules_stests_<workload>")
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
                  (resource "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`) VALUES (?,?,?,?) ON CONFLICT (`user_model_id`) DO NOTHING RETURNING `id`")
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
                        (resource "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`) VALUES (?,?,?,?) ON CONFLICT (`user_model_id`) DO NOTHING RETURNING `id`")
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
                  (name "gorm.delete")
                  (type "sql")
                  (resource "UPDATE `article_models` SET `deleted_at`=? WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL")
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
                        (resource "UPDATE `article_models` SET `deleted_at`=? WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL")
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
                  (service "gorm.db")
                  (name "gorm.query")
                  (type "sql")
                  (resource "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1")
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
                        (service "gorm.db")
                        (name "gorm.query")
                        (type "sql")
                        (resource "SELECT * FROM `article_tags` WHERE `article_tags`.`article_model_id` = ?")
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
                              (resource "SELECT * FROM `article_tags` WHERE `article_tags`.`article_model_id` = ?")
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
                        (resource "SELECT * FROM `article_user_models` WHERE `article_user_models`.`id` = ? AND `article_user_models`.`deleted_at` IS NULL")
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
                              (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ?")
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
                                    (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ?")
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
                              (resource "SELECT * FROM `article_user_models` WHERE `article_user_models`.`id` = ? AND `article_user_models`.`deleted_at` IS NULL")
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
                        (resource "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1")
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
                  (resource "SELECT * FROM `article_user_models` WHERE `article_user_models`.`user_model_id` = ? AND `article_user_models`.`deleted_at` IS NULL ORDER BY `article_user_models`.`id` LIMIT 1")
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
                        (resource "SELECT * FROM `article_user_models` WHERE `article_user_models`.`user_model_id` = ? AND `article_user_models`.`deleted_at` IS NULL ORDER BY `article_user_models`.`id` LIMIT 1")
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
            (resource "DELETE /api/articles/:slug/comments/:id")
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
                ("http.method" "DELETE")
                ("http.route" "/api/articles/:slug/comments/:id")
                ("http.status_code" "401")
                ("http.url" "http://<endpoint>/api/articles/some-slug/comments/1")
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
              ())))))
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
            (resource "DELETE /api/articles/:slug/comments/:id")
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
                ("http.method" "DELETE")
                ("http.route" "/api/articles/:slug/comments/:id")
                ("http.status_code" "404")
                ("http.url" "http://<endpoint>/api/articles/err-comment-art-rules_stests_<workload>/comments/99999")
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
                  (resource "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1")
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
                        (service "gorm.db")
                        (name "gorm.query")
                        (type "sql")
                        (resource "SELECT * FROM `article_tags` WHERE `article_tags`.`article_model_id` = ?")
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
                              (resource "SELECT * FROM `article_tags` WHERE `article_tags`.`article_model_id` = ?")
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
                        (resource "SELECT * FROM `article_user_models` WHERE `article_user_models`.`id` = ? AND `article_user_models`.`deleted_at` IS NULL")
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
                              (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ?")
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
                                    (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ?")
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
                              (resource "SELECT * FROM `article_user_models` WHERE `article_user_models`.`id` = ? AND `article_user_models`.`deleted_at` IS NULL")
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
                        (resource "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1")
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
                  (resource "SELECT * FROM `comment_models` WHERE (`comment_models`.`id` = ? AND `comment_models`.`article_id` = ?) AND `comment_models`.`deleted_at` IS NULL ORDER BY `comment_models`.`id` LIMIT 1")
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
                        (resource "SELECT * FROM `comment_models` WHERE (`comment_models`.`id` = ? AND `comment_models`.`article_id` = ?) AND `comment_models`.`deleted_at` IS NULL ORDER BY `comment_models`.`id` LIMIT 1")
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
            (resource "DELETE /api/articles/:slug/comments/:id")
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
                ("http.method" "DELETE")
                ("http.route" "/api/articles/:slug/comments/:id")
                ("http.status_code" "404")
                ("http.url" "http://<endpoint>/api/articles/unknown-slug-rules_stests_<workload>/comments/99999")
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
                  (resource "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1")
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
                        (resource "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1")
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
            (resource "GET /api/articles/:slug/comments")
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
                ("http.route" "/api/articles/:slug/comments")
                ("http.status_code" "404")
                ("http.url" "http://<endpoint>/api/articles/unknown-slug-rules_stests_<workload>/comments")
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
                  (resource "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1")
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
                        (resource "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1")
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
            (resource "POST /api/articles")
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
                ("http.route" "/api/articles")
                ("http.status_code" "201")
                ("http.url" "http://<endpoint>/api/articles")
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
                  (resource "INSERT INTO `article_models` (`created_at`,`updated_at`,`deleted_at`,`slug`,`title`,`description`,`body`,`author_id`) VALUES (?,?,?,?,?,?,?,?) RETURNING `id`")
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
                        (resource "INSERT INTO `article_models` (`created_at`,`updated_at`,`deleted_at`,`slug`,`title`,`description`,`body`,`author_id`) VALUES (?,?,?,?,?,?,?,?) RETURNING `id`")
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
                  (name "gorm.create")
                  (type "sql")
                  (resource "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`) VALUES (?,?,?,?) ON CONFLICT (`user_model_id`) DO NOTHING RETURNING `id`")
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
                        (resource "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`) VALUES (?,?,?,?) ON CONFLICT (`user_model_id`) DO NOTHING RETURNING `id`")
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
                  (name "gorm.create")
                  (type "sql")
                  (resource "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`) VALUES (?,?,?,?) ON CONFLICT (`user_model_id`) DO NOTHING RETURNING `id`")
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
                        (resource "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`) VALUES (?,?,?,?) ON CONFLICT (`user_model_id`) DO NOTHING RETURNING `id`")
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
                  (name "gorm.create")
                  (type "sql")
                  (resource "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`,`id`) VALUES (?,?,?,?,?) ON CONFLICT DO NOTHING RETURNING `id`")
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
                        (resource "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`,`id`) VALUES (?,?,?,?,?) ON CONFLICT DO NOTHING RETURNING `id`")
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
                  (name "gorm.create")
                  (type "sql")
                  (resource "INSERT INTO `user_models` (`username`,`email`,`bio`,`image`,`password`,`id`) VALUES (?,?,?,?,?,?) ON CONFLICT DO NOTHING RETURNING `id`")
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
                        (resource "INSERT INTO `user_models` (`username`,`email`,`bio`,`image`,`password`,`id`) VALUES (?,?,?,?,?,?) ON CONFLICT DO NOTHING RETURNING `id`")
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
                  (resource "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? ORDER BY `article_models`.`id` LIMIT 1")
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
                        (resource "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? ORDER BY `article_models`.`id` LIMIT 1")
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
                  (resource "SELECT * FROM `article_user_models` WHERE `article_user_models`.`user_model_id` = ? AND `article_user_models`.`deleted_at` IS NULL ORDER BY `article_user_models`.`id` LIMIT 1")
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
                        (resource "SELECT * FROM `article_user_models` WHERE `article_user_models`.`user_model_id` = ? AND `article_user_models`.`deleted_at` IS NULL ORDER BY `article_user_models`.`id` LIMIT 1")
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
                  (resource "SELECT * FROM `article_user_models` WHERE `article_user_models`.`user_model_id` = ? AND `article_user_models`.`deleted_at` IS NULL ORDER BY `article_user_models`.`id` LIMIT 1")
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
                        (resource "SELECT * FROM `article_user_models` WHERE `article_user_models`.`user_model_id` = ? AND `article_user_models`.`deleted_at` IS NULL ORDER BY `article_user_models`.`id` LIMIT 1")
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
                  (resource "SELECT * FROM `favorite_models` WHERE (`favorite_models`.`favorite_id` = ? AND `favorite_models`.`favorite_by_id` = ?) AND `favorite_models`.`deleted_at` IS NULL ORDER BY `favorite_models`.`id` LIMIT 1")
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
                        (resource "SELECT * FROM `favorite_models` WHERE (`favorite_models`.`favorite_id` = ? AND `favorite_models`.`favorite_by_id` = ?) AND `favorite_models`.`deleted_at` IS NULL ORDER BY `favorite_models`.`id` LIMIT 1")
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
                  (resource "SELECT * FROM `follow_models` WHERE (`follow_models`.`following_id` = ? AND `follow_models`.`followed_by_id` = ?) AND `follow_models`.`deleted_at` IS NULL ORDER BY `follow_models`.`id` LIMIT 1")
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
                        (resource "SELECT * FROM `follow_models` WHERE (`follow_models`.`following_id` = ? AND `follow_models`.`followed_by_id` = ?) AND `follow_models`.`deleted_at` IS NULL ORDER BY `follow_models`.`id` LIMIT 1")
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
                  (resource "SELECT count(*) FROM `favorite_models` WHERE `favorite_models`.`favorite_id` = ? AND `favorite_models`.`deleted_at` IS NULL")
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
                        (resource "SELECT count(*) FROM `favorite_models` WHERE `favorite_models`.`favorite_id` = ? AND `favorite_models`.`deleted_at` IS NULL")
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
            (resource "POST /api/articles/:slug/comments")
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
                ("http.route" "/api/articles/:slug/comments")
                ("http.status_code" "401")
                ("http.url" "http://<endpoint>/api/articles/some-slug/comments")
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
              ())))))
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
            (resource "POST /api/articles/:slug/comments")
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
                ("http.route" "/api/articles/:slug/comments")
                ("http.status_code" "404")
                ("http.url" "http://<endpoint>/api/articles/unknown-slug-rules_stests_<workload>/comments")
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
                  (resource "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1")
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
                        (resource "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1")
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
            (resource "POST /api/articles/:slug/comments")
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
                ("http.route" "/api/articles/:slug/comments")
                ("http.status_code" "422")
                ("http.url" "http://<endpoint>/api/articles/err-comment-art-rules_stests_<workload>/comments")
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
                  (resource "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1")
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
                        (service "gorm.db")
                        (name "gorm.query")
                        (type "sql")
                        (resource "SELECT * FROM `article_tags` WHERE `article_tags`.`article_model_id` = ?")
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
                              (resource "SELECT * FROM `article_tags` WHERE `article_tags`.`article_model_id` = ?")
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
                        (resource "SELECT * FROM `article_user_models` WHERE `article_user_models`.`id` = ? AND `article_user_models`.`deleted_at` IS NULL")
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
                              (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ?")
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
                                    (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ?")
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
                              (resource "SELECT * FROM `article_user_models` WHERE `article_user_models`.`id` = ? AND `article_user_models`.`deleted_at` IS NULL")
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
                        (resource "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1")
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
                  (resource "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1")
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
                        (service "gorm.db")
                        (name "gorm.query")
                        (type "sql")
                        (resource "SELECT * FROM `article_tags` WHERE `article_tags`.`article_model_id` = ?")
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
                              (resource "SELECT * FROM `article_tags` WHERE `article_tags`.`article_model_id` = ?")
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
                        (resource "SELECT * FROM `article_user_models` WHERE `article_user_models`.`id` = ? AND `article_user_models`.`deleted_at` IS NULL")
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
                              (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ?")
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
                                    (resource "SELECT * FROM `user_models` WHERE `user_models`.`id` = ?")
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
                              (resource "SELECT * FROM `article_user_models` WHERE `article_user_models`.`id` = ? AND `article_user_models`.`deleted_at` IS NULL")
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
                        (resource "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1")
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
                  (resource "Rollback")
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
                      ("sql.query_type" "Rollback")))
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
                    ()))))))))))
  ))
