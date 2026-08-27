use alloc::format;
use alloc::string::String;
use alloc::vec::Vec;
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
type ScalarValidator = fn(&Value) -> bool;

fn reject_unknown(value: &Value, context: &str, allowed: &[&str]) -> Result<(), String> {
    let Some(fields) = value.as_object() else {
        return Err(format!("invalid OTLP {context}: expected object"));
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
    for name in [snake, camel] {
        if let Some(field) = value.get(name) {
            if field.is_null() {
                if camel == snake {
                    break;
                }
                continue;
            }
            let Some(items) = field.as_array() else {
                return Err(format!(
                    "invalid OTLP repeated field {name:?}: expected array"
                ));
            };
            for item in items {
                validate(item)?;
            }
        }
        if camel == snake {
            break;
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

fn validate_scalar_field(
    value: &Value,
    snake: &str,
    camel: &str,
    context: &str,
    validate: ScalarValidator,
) -> Result<(), String> {
    for name in [snake, camel] {
        if let Some(item) = value.get(name) {
            // ProtoJSON accepts null for a singular field and treats it as unset.
            if !item.is_null() && !validate(item) {
                return Err(format!(
                    "invalid OTLP {context} field {name:?}: unexpected JSON type"
                ));
            }
        }
        if camel == snake {
            break;
        }
    }
    Ok(())
}

fn integer_scalar(value: &Value) -> bool {
    value.as_i64().is_some()
        || value.as_u64().is_some()
        || value
            .as_str()
            .is_some_and(|value| value.parse::<i64>().is_ok() || value.parse::<u64>().is_ok())
}

fn signed_integer_scalar(value: &Value) -> bool {
    value.as_i64().is_some()
        || value
            .as_str()
            .is_some_and(|value| value.parse::<i64>().is_ok())
}

fn i32_scalar(value: &Value) -> bool {
    value
        .as_i64()
        .is_some_and(|value| i32::try_from(value).is_ok())
        || value
            .as_u64()
            .is_some_and(|value| i32::try_from(value).is_ok())
        || value
            .as_str()
            .is_some_and(|value| value.parse::<i32>().is_ok())
}

fn enum_scalar(value: &Value) -> bool {
    value.as_i64().is_some() || value.as_u64().is_some()
}

fn double_scalar(value: &Value) -> bool {
    value.is_number()
        || value.as_str().is_some_and(|value| {
            matches!(value, "NaN" | "Infinity" | "-Infinity")
                || value.parse::<f64>().is_ok_and(f64::is_finite)
        })
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
    let populated_fields = fields.values().filter(|item| !item.is_null()).count();
    if populated_fields > 1 {
        return Err(format!(
            "invalid OTLP AnyValue: expected at most one variant, got {}",
            populated_fields
        ));
    }
    if populated_fields == 0 {
        return Ok(());
    }
    let (name, item) = fields.iter().find(|(_, item)| !item.is_null()).unwrap();
    let valid = match name.as_str() {
        "string_value" | "stringValue" => item.is_string(),
        "bytes_value" | "bytesValue" => item
            .as_str()
            .is_some_and(|value| decode_base64(value).is_some()),
        "bool_value" | "boolValue" => item.is_boolean(),
        "int_value" | "intValue" => {
            item.as_i64().is_some()
                || item.as_u64().is_some_and(|value| value <= i64::MAX as u64)
                || item
                    .as_str()
                    .is_some_and(|value| value.parse::<i64>().is_ok())
        }
        "double_value" | "doubleValue" => {
            double_scalar(item)
        }
        "array_value" | "arrayValue" => {
            if item.is_object() {
                validate_array_value(item)?;
                true
            } else {
                false
            }
        }
        "kvlist_value" | "kvlistValue" => {
            if item.is_object() {
                validate_key_value_list(item)?;
                true
            } else {
                false
            }
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
    validate_scalar_field(value, "kind", "kind", "span", enum_scalar)?;
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
    reject_unknown(value, "span status", &["message", "code"])?;
    validate_scalar_field(value, "message", "message", "span status", Value::is_string)?;
    validate_scalar_field(value, "code", "code", "span status", enum_scalar)
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
    validate_scalar_field(value, "name", "name", "metric", Value::is_string)?;
    validate_scalar_field(
        value,
        "description",
        "description",
        "metric",
        Value::is_string,
    )?;
    validate_scalar_field(value, "unit", "unit", "metric", Value::is_string)?;
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
    validate_scalar_field(
        value,
        "aggregation_temporality",
        "aggregationTemporality",
        "sum",
        enum_scalar,
    )?;
    validate_scalar_field(
        value,
        "is_monotonic",
        "isMonotonic",
        "sum",
        Value::is_boolean,
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
    validate_scalar_field(
        value,
        "aggregation_temporality",
        "aggregationTemporality",
        "histogram",
        enum_scalar,
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
    validate_scalar_field(
        value,
        "aggregation_temporality",
        "aggregationTemporality",
        "exponential histogram",
        enum_scalar,
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
    )?;
    validate_metric_point_scalars(value)?;
    validate_scalar_field(
        value,
        "as_double",
        "asDouble",
        "number data point",
        double_scalar,
    )?;
    validate_scalar_field(
        value,
        "as_int",
        "asInt",
        "number data point",
        signed_integer_scalar,
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
    )?;
    validate_metric_point_scalars(value)?;
    validate_scalar_field(
        value,
        "count",
        "count",
        "histogram data point",
        integer_scalar,
    )?;
    validate_scalar_field(value, "sum", "sum", "histogram data point", double_scalar)?;
    validate_scalar_field(value, "min", "min", "histogram data point", double_scalar)?;
    validate_scalar_field(value, "max", "max", "histogram data point", double_scalar)
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
    validate_metric_point_scalars(value)?;
    validate_scalar_field(
        value,
        "count",
        "count",
        "exponential histogram data point",
        integer_scalar,
    )?;
    validate_scalar_field(
        value,
        "sum",
        "sum",
        "exponential histogram data point",
        double_scalar,
    )?;
    validate_scalar_field(
        value,
        "scale",
        "scale",
        "exponential histogram data point",
        integer_scalar,
    )?;
    validate_scalar_field(
        value,
        "zero_count",
        "zeroCount",
        "exponential histogram data point",
        integer_scalar,
    )?;
    validate_scalar_field(
        value,
        "min",
        "min",
        "exponential histogram data point",
        double_scalar,
    )?;
    validate_scalar_field(
        value,
        "max",
        "max",
        "exponential histogram data point",
        double_scalar,
    )?;
    validate_scalar_field(
        value,
        "zero_threshold",
        "zeroThreshold",
        "exponential histogram data point",
        double_scalar,
    )?;
    validate_object_field(value, "positive", "positive", validate_buckets)?;
    validate_object_field(value, "negative", "negative", validate_buckets)
}

fn validate_buckets(value: &Value) -> Result<(), String> {
    reject_unknown(
        value,
        "exponential histogram buckets",
        &["offset", "bucket_counts", "bucketCounts"],
    )?;
    validate_scalar_field(
        value,
        "offset",
        "offset",
        "exponential histogram buckets",
        i32_scalar,
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
    validate_metric_point_scalars(value)?;
    validate_scalar_field(
        value,
        "count",
        "count",
        "summary data point",
        integer_scalar,
    )?;
    validate_scalar_field(value, "sum", "sum", "summary data point", double_scalar)?;
    validate_array_field(
        value,
        "quantile_values",
        "quantileValues",
        validate_quantile,
    )
}

fn validate_quantile(value: &Value) -> Result<(), String> {
    reject_unknown(value, "summary quantile", &["quantile", "value"])?;
    validate_scalar_field(
        value,
        "quantile",
        "quantile",
        "summary quantile",
        double_scalar,
    )?;
    validate_scalar_field(value, "value", "value", "summary quantile", double_scalar)
}

fn validate_metric_point_scalars(value: &Value) -> Result<(), String> {
    validate_scalar_field(
        value,
        "start_time_unix_nano",
        "startTimeUnixNano",
        "metric data point",
        integer_scalar,
    )?;
    validate_scalar_field(
        value,
        "time_unix_nano",
        "timeUnixNano",
        "metric data point",
        integer_scalar,
    )?;
    validate_scalar_field(value, "flags", "flags", "metric data point", integer_scalar)
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
    validate_scalar_field(
        value,
        "time_unix_nano",
        "timeUnixNano",
        "exemplar",
        integer_scalar,
    )?;
    validate_scalar_field(value, "as_double", "asDouble", "exemplar", double_scalar)?;
    validate_scalar_field(value, "as_int", "asInt", "exemplar", signed_integer_scalar)?;
    validate_scalar_field(value, "span_id", "spanId", "exemplar", Value::is_string)?;
    validate_scalar_field(value, "trace_id", "traceId", "exemplar", Value::is_string)?;
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
    validate_array_field(value, "attributes", "attributes", validate_key_value)?;
    validate_scalar_field(
        value,
        "severity_number",
        "severityNumber",
        "log record",
        enum_scalar,
    )?;
    validate_scalar_field(value, "flags", "flags", "log record", trace_flags_scalar)
}

fn trace_flags_scalar(value: &Value) -> bool {
    integer_value(value).is_some_and(|flags| matches!(flags, 0 | 1))
}

fn integer_value(value: &Value) -> Option<i128> {
    value
        .as_i64()
        .map(i128::from)
        .or_else(|| value.as_u64().map(i128::from))
        .or_else(|| value.as_str().and_then(|value| value.parse::<i128>().ok()))
}

pub(crate) fn decode_base64(encoded: &str) -> Option<Vec<u8>> {
    let mut output = Vec::with_capacity(encoded.len().saturating_mul(3) / 4);
    let mut buffer = 0_u32;
    let mut bits = 0_u8;
    let mut data_characters = 0_usize;
    let mut padding = 0_usize;
    for byte in encoded.bytes() {
        if byte == b'=' {
            padding += 1;
            if padding > 2 {
                return None;
            }
            continue;
        }
        if padding != 0 {
            return None;
        }
        let value = match byte {
            b'A'..=b'Z' => byte - b'A',
            b'a'..=b'z' => byte - b'a' + 26,
            b'0'..=b'9' => byte - b'0' + 52,
            b'+' | b'-' => 62,
            b'/' | b'_' => 63,
            _ => return None,
        };
        data_characters += 1;
        buffer = (buffer << 6) | u32::from(value);
        bits += 6;
        if bits >= 8 {
            bits -= 8;
            output.push((buffer >> bits) as u8);
            buffer &= (1_u32 << bits) - 1;
        }
    }
    let remainder = data_characters % 4;
    if remainder == 1
        || (padding != 0 && (data_characters + padding) % 4 != 0)
        || (padding == 1 && remainder != 3)
        || (padding == 2 && remainder != 2)
        || buffer != 0
    {
        return None;
    }
    Some(output)
}
