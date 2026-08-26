use alloc::format;
use alloc::string::String;
use serde_json::Value;

pub(crate) fn validate_export(signal: &str, value: &Value) -> Result<(), String> {
    value
        .as_object()
        .ok_or_else(|| format!("invalid OTLP {signal} JSON export: expected object"))?;
    match signal {
        "traces" => {
            reject_unknown(
                value,
                "traces JSON export",
                &["resource_spans", "resourceSpans"],
            )?;
            validate_array_field(
                value,
                "resource_spans",
                "resourceSpans",
                validate_resource_spans,
            )
        }
        "metrics" => {
            reject_unknown(
                value,
                "metrics JSON export",
                &["resource_metrics", "resourceMetrics"],
            )?;
            validate_array_field(
                value,
                "resource_metrics",
                "resourceMetrics",
                validate_resource_metrics,
            )
        }
        "logs" => {
            reject_unknown(
                value,
                "logs JSON export",
                &["resource_logs", "resourceLogs"],
            )?;
            validate_array_field(
                value,
                "resource_logs",
                "resourceLogs",
                validate_resource_logs,
            )
        }
        _ => unreachable!(),
    }
}

type Validator = fn(&Value) -> Result<(), String>;

fn reject_unknown(value: &Value, context: &str, allowed: &[&str]) -> Result<(), String> {
    let Some(fields) = value.as_object() else {
        return Ok(());
    };
    if let Some(name) = fields.keys().find(|name| !allowed.contains(&name.as_str())) {
        return Err(format!("invalid OTLP {context} field {name:?}"));
    }
    Ok(())
}

fn validate_array_field(
    value: &Value,
    snake: &str,
    camel: &str,
    validate: Validator,
) -> Result<(), String> {
    if let Some(items) = value.get(snake).and_then(Value::as_array) {
        for item in items {
            validate(item)?;
        }
    }
    if camel != snake {
        if let Some(items) = value.get(camel).and_then(Value::as_array) {
            for item in items {
                validate(item)?;
            }
        }
    }
    Ok(())
}

fn validate_object_field(
    value: &Value,
    snake: &str,
    camel: &str,
    validate: Validator,
) -> Result<(), String> {
    validate_named_object(value, snake, validate)?;
    if camel != snake {
        validate_named_object(value, camel, validate)?;
    }
    Ok(())
}

fn validate_named_object(value: &Value, name: &str, validate: Validator) -> Result<(), String> {
    let Some(item) = value.get(name) else {
        return Ok(());
    };
    if item.is_null() {
        // ProtoJSON accepts null for any message field and treats it as unset.
        return Ok(());
    }
    if !item.is_object() {
        return Err(format!(
            "invalid OTLP object field {name:?}: expected object"
        ));
    }
    validate(item)
}

fn validate_resource(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "resource",
        &[
            "attributes",
            "dropped_attributes_count",
            "droppedAttributesCount",
            "entity_refs",
            "entityRefs",
        ],
    )?;
    validate_array_field(value, "attributes", "attributes", validate_key_value)?;
    validate_array_field(value, "entity_refs", "entityRefs", validate_entity_ref)
}

fn validate_entity_ref(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "entity reference",
        &[
            "schema_url",
            "schemaUrl",
            "type",
            "id_keys",
            "idKeys",
            "description_keys",
            "descriptionKeys",
        ],
    )
}

fn validate_scope(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "instrumentation scope",
        &[
            "name",
            "version",
            "attributes",
            "dropped_attributes_count",
            "droppedAttributesCount",
        ],
    )?;
    validate_array_field(value, "attributes", "attributes", validate_key_value)
}

fn validate_key_value(value: &Value) -> Result<(), String> {
    reject_unknown(value, "key/value", &["key", "value"])?;
    validate_object_field(value, "value", "value", validate_any_value)
}

fn validate_any_value(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "AnyValue",
        &[
            "string_value",
            "stringValue",
            "bool_value",
            "boolValue",
            "int_value",
            "intValue",
            "double_value",
            "doubleValue",
            "array_value",
            "arrayValue",
            "kvlist_value",
            "kvlistValue",
            "bytes_value",
            "bytesValue",
        ],
    )?;
    let fields = value
        .as_object()
        .ok_or_else(|| String::from("invalid OTLP AnyValue: expected object"))?;
    if fields.len() != 1 {
        return Err(format!(
            "invalid OTLP AnyValue: expected exactly one variant, got {}",
            fields.len()
        ));
    }
    let (name, item) = fields.iter().next().unwrap();
    let valid = match name.as_str() {
        "string_value" | "stringValue" | "bytes_value" | "bytesValue" => item.is_string(),
        "bool_value" | "boolValue" => item.is_boolean(),
        "int_value" | "intValue" => {
            item.as_i64().is_some()
                || item.as_u64().is_some_and(|value| value <= i64::MAX as u64)
                || item
                    .as_str()
                    .is_some_and(|value| value.parse::<i64>().is_ok())
        }
        "double_value" | "doubleValue" => {
            item.is_number() || matches!(item.as_str(), Some("NaN" | "Infinity" | "-Infinity"))
        }
        "array_value" | "arrayValue" => {
            validate_object_field(value, name, name, validate_array_value)?;
            true
        }
        "kvlist_value" | "kvlistValue" => {
            validate_object_field(value, name, name, validate_key_value_list)?;
            true
        }
        _ => unreachable!(),
    };
    if !valid {
        return Err(format!(
            "invalid OTLP AnyValue variant {name:?}: unexpected JSON type"
        ));
    }
    Ok(())
}

fn validate_array_value(value: &Value) -> Result<(), String> {
    reject_unknown(value, "ArrayValue", &["values"])?;
    validate_array_field(value, "values", "values", validate_any_value)
}

fn validate_key_value_list(value: &Value) -> Result<(), String> {
    reject_unknown(value, "KeyValueList", &["values"])?;
    validate_array_field(value, "values", "values", validate_key_value)
}

fn validate_resource_spans(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "ResourceSpans",
        &[
            "resource",
            "scope_spans",
            "scopeSpans",
            "schema_url",
            "schemaUrl",
        ],
    )?;
    validate_object_field(value, "resource", "resource", validate_resource)?;
    validate_array_field(value, "scope_spans", "scopeSpans", validate_scope_spans)
}

fn validate_scope_spans(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "ScopeSpans",
        &["scope", "spans", "schema_url", "schemaUrl"],
    )?;
    validate_object_field(value, "scope", "scope", validate_scope)?;
    validate_array_field(value, "spans", "spans", validate_span)
}

fn validate_span(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "span",
        &[
            "trace_id",
            "traceId",
            "span_id",
            "spanId",
            "trace_state",
            "traceState",
            "parent_span_id",
            "parentSpanId",
            "name",
            "kind",
            "start_time_unix_nano",
            "startTimeUnixNano",
            "end_time_unix_nano",
            "endTimeUnixNano",
            "attributes",
            "dropped_attributes_count",
            "droppedAttributesCount",
            "events",
            "dropped_events_count",
            "droppedEventsCount",
            "links",
            "dropped_links_count",
            "droppedLinksCount",
            "status",
            "flags",
        ],
    )?;
    validate_array_field(value, "attributes", "attributes", validate_key_value)?;
    validate_array_field(value, "events", "events", validate_span_event)?;
    validate_array_field(value, "links", "links", validate_span_link)?;
    validate_object_field(value, "status", "status", validate_status)
}

fn validate_span_event(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "span event",
        &[
            "time_unix_nano",
            "timeUnixNano",
            "name",
            "attributes",
            "dropped_attributes_count",
            "droppedAttributesCount",
        ],
    )?;
    validate_array_field(value, "attributes", "attributes", validate_key_value)
}

fn validate_span_link(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "span link",
        &[
            "trace_id",
            "traceId",
            "span_id",
            "spanId",
            "trace_state",
            "traceState",
            "attributes",
            "dropped_attributes_count",
            "droppedAttributesCount",
            "flags",
        ],
    )?;
    validate_array_field(value, "attributes", "attributes", validate_key_value)
}

fn validate_status(value: &Value) -> Result<(), String> {
    reject_unknown(value, "span status", &["message", "code"])
}

fn validate_resource_metrics(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "ResourceMetrics",
        &[
            "resource",
            "scope_metrics",
            "scopeMetrics",
            "schema_url",
            "schemaUrl",
        ],
    )?;
    validate_object_field(value, "resource", "resource", validate_resource)?;
    validate_array_field(
        value,
        "scope_metrics",
        "scopeMetrics",
        validate_scope_metrics,
    )
}

fn validate_scope_metrics(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "ScopeMetrics",
        &["scope", "metrics", "schema_url", "schemaUrl"],
    )?;
    validate_object_field(value, "scope", "scope", validate_scope)?;
    validate_array_field(value, "metrics", "metrics", validate_metric)
}

fn validate_metric(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "metric",
        &[
            "name",
            "description",
            "unit",
            "gauge",
            "sum",
            "histogram",
            "exponential_histogram",
            "exponentialHistogram",
            "summary",
            "metadata",
        ],
    )?;
    validate_array_field(value, "metadata", "metadata", validate_key_value)?;
    validate_object_field(value, "gauge", "gauge", validate_gauge)?;
    validate_object_field(value, "sum", "sum", validate_sum)?;
    validate_object_field(value, "histogram", "histogram", validate_histogram)?;
    validate_object_field(
        value,
        "exponential_histogram",
        "exponentialHistogram",
        validate_exponential_histogram,
    )?;
    validate_object_field(value, "summary", "summary", validate_summary)
}

fn validate_gauge(value: &Value) -> Result<(), String> {
    reject_unknown(value, "gauge", &["data_points", "dataPoints"])?;
    validate_array_field(
        value,
        "data_points",
        "dataPoints",
        validate_number_data_point,
    )
}

fn validate_sum(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "sum",
        &[
            "data_points",
            "dataPoints",
            "aggregation_temporality",
            "aggregationTemporality",
            "is_monotonic",
            "isMonotonic",
        ],
    )?;
    validate_array_field(
        value,
        "data_points",
        "dataPoints",
        validate_number_data_point,
    )
}

fn validate_histogram(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "histogram",
        &[
            "data_points",
            "dataPoints",
            "aggregation_temporality",
            "aggregationTemporality",
        ],
    )?;
    validate_array_field(
        value,
        "data_points",
        "dataPoints",
        validate_histogram_data_point,
    )
}

fn validate_exponential_histogram(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "exponential histogram",
        &[
            "data_points",
            "dataPoints",
            "aggregation_temporality",
            "aggregationTemporality",
        ],
    )?;
    validate_array_field(
        value,
        "data_points",
        "dataPoints",
        validate_exponential_histogram_data_point,
    )
}

fn validate_summary(value: &Value) -> Result<(), String> {
    reject_unknown(value, "summary", &["data_points", "dataPoints"])?;
    validate_array_field(
        value,
        "data_points",
        "dataPoints",
        validate_summary_data_point,
    )
}

fn validate_point_common(value: &Value, allowed: &[&str]) -> Result<(), String> {
    reject_unknown(value, "metric data point", allowed)?;
    validate_array_field(value, "attributes", "attributes", validate_key_value)?;
    validate_array_field(value, "exemplars", "exemplars", validate_exemplar)
}

fn validate_number_data_point(value: &Value) -> Result<(), String> {
    validate_point_common(
        value,
        &[
            "attributes",
            "start_time_unix_nano",
            "startTimeUnixNano",
            "time_unix_nano",
            "timeUnixNano",
            "as_double",
            "asDouble",
            "as_int",
            "asInt",
            "exemplars",
            "flags",
        ],
    )
}

fn validate_histogram_data_point(value: &Value) -> Result<(), String> {
    validate_point_common(
        value,
        &[
            "attributes",
            "start_time_unix_nano",
            "startTimeUnixNano",
            "time_unix_nano",
            "timeUnixNano",
            "count",
            "sum",
            "bucket_counts",
            "bucketCounts",
            "explicit_bounds",
            "explicitBounds",
            "exemplars",
            "flags",
            "min",
            "max",
        ],
    )
}

fn validate_exponential_histogram_data_point(value: &Value) -> Result<(), String> {
    validate_point_common(
        value,
        &[
            "attributes",
            "start_time_unix_nano",
            "startTimeUnixNano",
            "time_unix_nano",
            "timeUnixNano",
            "count",
            "sum",
            "scale",
            "zero_count",
            "zeroCount",
            "positive",
            "negative",
            "flags",
            "exemplars",
            "min",
            "max",
            "zero_threshold",
            "zeroThreshold",
        ],
    )?;
    validate_object_field(value, "positive", "positive", validate_buckets)?;
    validate_object_field(value, "negative", "negative", validate_buckets)
}

fn validate_buckets(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "exponential histogram buckets",
        &["offset", "bucket_counts", "bucketCounts"],
    )
}

fn validate_summary_data_point(value: &Value) -> Result<(), String> {
    validate_point_common(
        value,
        &[
            "attributes",
            "start_time_unix_nano",
            "startTimeUnixNano",
            "time_unix_nano",
            "timeUnixNano",
            "count",
            "sum",
            "quantile_values",
            "quantileValues",
            "flags",
        ],
    )?;
    validate_array_field(
        value,
        "quantile_values",
        "quantileValues",
        validate_quantile,
    )
}

fn validate_quantile(value: &Value) -> Result<(), String> {
    reject_unknown(value, "summary quantile", &["quantile", "value"])
}

fn validate_exemplar(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "exemplar",
        &[
            "filtered_attributes",
            "filteredAttributes",
            "time_unix_nano",
            "timeUnixNano",
            "as_double",
            "asDouble",
            "as_int",
            "asInt",
            "span_id",
            "spanId",
            "trace_id",
            "traceId",
        ],
    )?;
    validate_array_field(
        value,
        "filtered_attributes",
        "filteredAttributes",
        validate_key_value,
    )
}

fn validate_resource_logs(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "ResourceLogs",
        &[
            "resource",
            "scope_logs",
            "scopeLogs",
            "schema_url",
            "schemaUrl",
        ],
    )?;
    validate_object_field(value, "resource", "resource", validate_resource)?;
    validate_array_field(value, "scope_logs", "scopeLogs", validate_scope_logs)
}

fn validate_scope_logs(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "ScopeLogs",
        &[
            "scope",
            "log_records",
            "logRecords",
            "schema_url",
            "schemaUrl",
        ],
    )?;
    validate_object_field(value, "scope", "scope", validate_scope)?;
    validate_array_field(value, "log_records", "logRecords", validate_log_record)
}

fn validate_log_record(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "log record",
        &[
            "time_unix_nano",
            "timeUnixNano",
            "observed_time_unix_nano",
            "observedTimeUnixNano",
            "severity_number",
            "severityNumber",
            "severity_text",
            "severityText",
            "body",
            "attributes",
            "dropped_attributes_count",
            "droppedAttributesCount",
            "flags",
            "trace_id",
            "traceId",
            "span_id",
            "spanId",
            "event_name",
            "eventName",
        ],
    )?;
    validate_object_field(value, "body", "body", validate_any_value)?;
    validate_array_field(value, "attributes", "attributes", validate_key_value)
}
