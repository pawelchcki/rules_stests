use crate::data::{Payload, Record};
use crate::proto;
use alloc::collections::BTreeMap;
use alloc::format;
use alloc::string::String;
use alloc::vec::Vec;
use core::fmt::Write;
use serde_json::Value;

pub fn capture_to_scheme(records: &[Record]) -> Result<Vec<u8>, String> {
    if records
        .iter()
        .all(|record| !matches!(record.payload, Payload::Json(_)))
    {
        typed_capture_to_scheme(records)
    } else {
        json_capture_to_scheme(records)
    }
}

fn typed_capture_to_scheme(records: &[Record]) -> Result<Vec<u8>, String> {
    let mut span_index = BTreeMap::<String, (usize, String)>::new();
    for record in records {
        if let Payload::Traces(payload) = &record.payload {
            for resource in &payload.resource_spans {
                for group in &resource.scope_spans {
                    for span in &group.spans {
                        let span_id = hex_text(&span.span_id);
                        let trace_id = hex_text(&span.trace_id);
                        span_index
                            .entry(span_id)
                            .and_modify(|entry| entry.0 += 1)
                            .or_insert((1, trace_id));
                    }
                }
            }
        }
    }
    let mut output = String::from("((requests (\n");
    write_requests(&mut output, records);
    output.push_str("))\n(resources (\n");
    for record in records {
        match &record.payload {
            Payload::Traces(payload) => {
                for item in &payload.resource_spans {
                    write_typed_resource(&mut output, &record.signal, item.resource.as_ref());
                }
            }
            Payload::Metrics(payload) => {
                for item in &payload.resource_metrics {
                    write_typed_resource(&mut output, &record.signal, item.resource.as_ref());
                }
            }
            Payload::Logs(payload) => {
                for item in &payload.resource_logs {
                    write_typed_resource(&mut output, &record.signal, item.resource.as_ref());
                }
            }
            Payload::Json(_) => unreachable!(),
        }
    }
    output.push_str("))\n(scopes (\n");
    for record in records {
        if let Payload::Traces(payload) = &record.payload {
            for resource in &payload.resource_spans {
                for group in &resource.scope_spans {
                    let scope = group.scope.as_ref();
                    output.push_str("  ((name ");
                    string(
                        &mut output,
                        scope.map(|scope| scope.name.as_str()).unwrap_or(""),
                    );
                    output.push_str(") (version ");
                    string(
                        &mut output,
                        scope.map(|scope| scope.version.as_str()).unwrap_or(""),
                    );
                    output.push_str(") (attributes ");
                    typed_attributes(
                        &mut output,
                        scope
                            .map(|scope| scope.attributes.as_slice())
                            .unwrap_or(&[]),
                    );
                    write!(
                        output,
                        ") (dropped-attributes {}))\n",
                        scope
                            .map(|scope| scope.dropped_attributes_count)
                            .unwrap_or(0)
                    )
                    .unwrap();
                }
            }
        }
    }
    output.push_str("))\n(spans (\n");
    for record in records {
        if let Payload::Traces(payload) = &record.payload {
            for resource in &payload.resource_spans {
                for group in &resource.scope_spans {
                    let scope_name = group
                        .scope
                        .as_ref()
                        .map(|scope| scope.name.as_str())
                        .unwrap_or("");
                    for span in &group.spans {
                        write_typed_span(&mut output, scope_name, span, &span_index);
                    }
                }
            }
        }
    }
    output.push_str("))\n(metrics (\n");
    for record in records {
        if let Payload::Metrics(payload) = &record.payload {
            for resource in &payload.resource_metrics {
                for group in &resource.scope_metrics {
                    let scope = group
                        .scope
                        .as_ref()
                        .map(|scope| scope.name.as_str())
                        .unwrap_or("");
                    for metric in &group.metrics {
                        let (data_type, data_points) = typed_metric_data(metric);
                        output.push_str("  ((scope ");
                        string(&mut output, scope);
                        output.push_str(") (name ");
                        string(&mut output, &metric.name);
                        write!(
                            output,
                            ") (data-type {data_type}) (data-points {data_points}))\n"
                        )
                        .unwrap();
                    }
                }
            }
        }
    }
    output.push_str("))\n(logs (\n");
    for record in records {
        if let Payload::Logs(payload) = &record.payload {
            for resource in &payload.resource_logs {
                for group in &resource.scope_logs {
                    let scope = group
                        .scope
                        .as_ref()
                        .map(|scope| scope.name.as_str())
                        .unwrap_or("");
                    for log in &group.log_records {
                        output.push_str("  ((scope ");
                        string(&mut output, scope);
                        write!(
                            output,
                            ") (time {}) (observed-time {}) (severity-number {}) (severity-text ",
                            log.time_unix_nano, log.observed_time_unix_nano, log.severity_number
                        )
                        .unwrap();
                        string(&mut output, &log.severity_text);
                        output.push_str(") (body ");
                        typed_any_value(&mut output, log.body.as_ref());
                        output.push_str(") (attributes ");
                        typed_attributes(&mut output, &log.attributes);
                        write!(
                            output,
                            ") (dropped-attributes {}) (flags {}) (trace-id ",
                            log.dropped_attributes_count, log.flags
                        )
                        .unwrap();
                        string(&mut output, &hex_text(&log.trace_id));
                        output.push_str(") (span-id ");
                        string(&mut output, &hex_text(&log.span_id));
                        output.push_str(") (event-name ");
                        string(&mut output, &log.event_name);
                        output.push_str("))\n");
                    }
                }
            }
        }
    }
    output.push_str(")))\n");
    Ok(output.into_bytes())
}

fn typed_metric_data(metric: &proto::Metric) -> (&'static str, usize) {
    match metric.data.as_ref() {
        Some(proto::metric::Data::Gauge(data)) => ("gauge", data.data_points.len()),
        Some(proto::metric::Data::Sum(data)) => ("sum", data.data_points.len()),
        Some(proto::metric::Data::Histogram(data)) => ("histogram", data.data_points.len()),
        Some(proto::metric::Data::ExponentialHistogram(data)) => {
            ("exponential-histogram", data.data_points.len())
        }
        Some(proto::metric::Data::Summary(data)) => ("summary", data.data_points.len()),
        None => ("missing", 0),
    }
}

fn write_requests(output: &mut String, records: &[Record]) {
    for record in records {
        output.push_str("  ((signal ");
        output.push_str(&record.signal);
        write!(
            output,
            ") (received-unix-nano {}) (remote-address ",
            record.received_unix_nano
        )
        .unwrap();
        string(output, &record.remote_address);
        output.push_str(") (method ");
        string(output, &record.request.method);
        output.push_str(") (path ");
        string(output, &record.request.path);
        output.push_str(") (http-version ");
        string(output, &record.request.http_version);
        output.push_str(") (content-type ");
        string(output, &record.request.content_type);
        output.push_str(") (content-encoding ");
        string(output, &record.request.content_encoding);
        write!(
            output,
            ") (content-length {}) (decoded-length {}) (headers (",
            record.request.content_length, record.request.decoded_length
        )
        .unwrap();
        for header in &record.request.headers {
            output.push('(');
            string(output, &header.name);
            output.push(' ');
            string(output, &header.value);
            output.push(')');
        }
        output.push_str(")))\n");
    }
}

fn write_typed_resource(output: &mut String, signal: &str, resource: Option<&proto::Resource>) {
    output.push_str("  ((signal ");
    output.push_str(signal);
    output.push_str(") (attributes ");
    typed_attributes(
        output,
        resource
            .map(|resource| resource.attributes.as_slice())
            .unwrap_or(&[]),
    );
    write!(
        output,
        ") (dropped-attributes {}) (entity-refs {}))\n",
        resource
            .map(|resource| resource.dropped_attributes_count)
            .unwrap_or(0),
        resource
            .map(|resource| resource.entity_refs.len())
            .unwrap_or(0)
    )
    .unwrap();
}

fn write_typed_span(
    output: &mut String,
    scope: &str,
    span: &proto::Span,
    index: &BTreeMap<String, (usize, String)>,
) {
    let trace_id = hex_text(&span.trace_id);
    let span_id = hex_text(&span.span_id);
    let parent_id = hex_text(&span.parent_span_id);
    let id_count = index.get(&span_id).map(|entry| entry.0).unwrap_or(0);
    let (parent_class, parent_trace_matches) = if parent_id.is_empty() {
        ("root", true)
    } else if let Some((_, parent_trace)) = index.get(&parent_id) {
        ("child", parent_trace == &trace_id)
    } else {
        ("external", true)
    };
    output.push_str("  ((scope ");
    string(output, scope);
    output.push_str(") (trace-id ");
    string(output, &trace_id);
    output.push_str(") (span-id ");
    string(output, &span_id);
    output.push_str(") (parent-span-id ");
    string(output, &parent_id);
    write!(output, ") (id-count {id_count}) (parent-class {parent_class}) (parent-trace-matches {}) (trace-state ", if parent_trace_matches { "#t" } else { "#f" }).unwrap();
    string(output, &span.trace_state);
    output.push_str(") (name ");
    string(output, &span.name);
    write!(
        output,
        ") (kind {}) (start {}) (end {}) (attributes ",
        span.kind, span.start_time_unix_nano, span.end_time_unix_nano
    )
    .unwrap();
    typed_attributes(output, &span.attributes);
    write!(
        output,
        ") (dropped-attributes {}) (events (",
        span.dropped_attributes_count
    )
    .unwrap();
    for event in &span.events {
        output.push_str("((name ");
        string(output, &event.name);
        write!(
            output,
            ") (time {}) (dropped-attributes {}) (attributes ",
            event.time_unix_nano, event.dropped_attributes_count
        )
        .unwrap();
        typed_attributes(output, &event.attributes);
        output.push_str("))");
    }
    write!(
        output,
        ")) (dropped-events {}) (links (",
        span.dropped_events_count
    )
    .unwrap();
    for link in &span.links {
        output.push_str("((trace-id ");
        string(output, &hex_text(&link.trace_id));
        output.push_str(") (span-id ");
        string(output, &hex_text(&link.span_id));
        write!(
            output,
            ") (dropped-attributes {}) (flags {}))",
            link.dropped_attributes_count, link.flags
        )
        .unwrap();
    }
    let status = span.status.as_ref();
    write!(
        output,
        ")) (dropped-links {}) (status-code {}) (status-message ",
        span.dropped_links_count,
        status.map(|status| status.code).unwrap_or(0)
    )
    .unwrap();
    string(
        output,
        status.map(|status| status.message.as_str()).unwrap_or(""),
    );
    write!(output, ") (flags {}))\n", span.flags).unwrap();
}

fn typed_attributes(output: &mut String, attributes: &[proto::KeyValue]) {
    output.push('(');
    for attribute in attributes {
        output.push('(');
        string(output, &attribute.key);
        output.push(' ');
        typed_any_value(output, attribute.value.as_ref());
        output.push(')');
    }
    output.push(')');
}

fn typed_any_value(output: &mut String, value: Option<&proto::AnyValue>) {
    match value.and_then(|value| value.value.as_ref()) {
        Some(proto::any_value::Value::StringValue(value)) if value.len() > 256 => {
            write!(output, "(long-string {})", value.len()).unwrap()
        }
        Some(proto::any_value::Value::StringValue(value)) => {
            output.push_str("(string ");
            string(output, value);
            output.push(')');
        }
        Some(proto::any_value::Value::IntValue(value)) => {
            write!(output, "(integer {value})").unwrap()
        }
        Some(proto::any_value::Value::BoolValue(value)) => output.push_str(if *value {
            "(boolean #t)"
        } else {
            "(boolean #f)"
        }),
        Some(proto::any_value::Value::DoubleValue(value)) => {
            output.push_str("(double ");
            string(output, &format!("{value}"));
            output.push(')');
        }
        Some(proto::any_value::Value::BytesValue(value)) => {
            output.push_str("(bytes (");
            for byte in value {
                write!(output, "{byte} ").unwrap();
            }
            output.push_str("))");
        }
        _ => output.push_str("(other)"),
    }
}

fn hex_text(bytes: &[u8]) -> String {
    const DIGITS: &[u8; 16] = b"0123456789abcdef";
    let mut output = String::with_capacity(bytes.len() * 2);
    for byte in bytes {
        output.push(DIGITS[(byte >> 4) as usize] as char);
        output.push(DIGITS[(byte & 15) as usize] as char);
    }
    output
}

fn json_capture_to_scheme(records: &[Record]) -> Result<Vec<u8>, String> {
    let payloads = records
        .iter()
        .map(|record| {
            serde_json::to_value(&record.payload)
                .map_err(|error| format!("serialize OTLP payload for Scheme: {error}"))
        })
        .collect::<Result<Vec<_>, _>>()?;
    let span_index = span_index(&payloads);
    let mut output = String::from("((requests (\n");
    for record in records {
        output.push_str("  ((signal ");
        output.push_str(&record.signal);
        write!(
            output,
            ") (received-unix-nano {}) (remote-address ",
            record.received_unix_nano
        )
        .unwrap();
        string(&mut output, &record.remote_address);
        output.push_str(") (method ");
        string(&mut output, &record.request.method);
        output.push_str(") (path ");
        string(&mut output, &record.request.path);
        output.push_str(") (http-version ");
        string(&mut output, &record.request.http_version);
        output.push_str(") (content-type ");
        string(&mut output, &record.request.content_type);
        output.push_str(") (content-encoding ");
        string(&mut output, &record.request.content_encoding);
        write!(
            output,
            ") (content-length {}) (decoded-length {}) (headers (",
            record.request.content_length, record.request.decoded_length
        )
        .unwrap();
        for header in &record.request.headers {
            output.push('(');
            string(&mut output, &header.name);
            output.push(' ');
            string(&mut output, &header.value);
            output.push(')');
        }
        output.push_str(")))\n");
    }
    output.push_str("))\n(resources (\n");
    for (record, payload) in records.iter().zip(&payloads) {
        for resource in resources(payload, &record.signal) {
            output.push_str("  ((signal ");
            output.push_str(&record.signal);
            output.push_str(") (attributes ");
            attributes(&mut output, resource.get("attributes"));
            write!(
                output,
                ") (dropped-attributes {}) (entity-refs {}))\n",
                integer(json_field(
                    resource,
                    "dropped_attributes_count",
                    "droppedAttributesCount"
                )),
                length(json_field(resource, "entity_refs", "entityRefs"))
            )
            .unwrap();
        }
    }
    output.push_str("))\n(scopes (\n");
    for payload in trace_payloads(records, &payloads) {
        for group in trace_groups(payload) {
            let scope = group.get("scope").unwrap_or(&Value::Null);
            output.push_str("  ((name ");
            string(&mut output, text(scope.get("name")));
            output.push_str(") (version ");
            string(&mut output, text(scope.get("version")));
            output.push_str(") (attributes ");
            attributes(&mut output, scope.get("attributes"));
            write!(
                output,
                ") (dropped-attributes {}))\n",
                integer(json_field(
                    scope,
                    "dropped_attributes_count",
                    "droppedAttributesCount"
                ))
            )
            .unwrap();
        }
    }
    output.push_str("))\n(spans (\n");
    for payload in trace_payloads(records, &payloads) {
        for group in trace_groups(payload) {
            let scope = group.get("scope").unwrap_or(&Value::Null);
            for span in array(group.get("spans")) {
                output.push_str("  ((scope ");
                string(&mut output, text(scope.get("name")));
                output.push_str(") (trace-id ");
                string(&mut output, text(json_field(span, "trace_id", "traceId")));
                output.push_str(") (span-id ");
                string(&mut output, text(json_field(span, "span_id", "spanId")));
                output.push_str(") (parent-span-id ");
                string(
                    &mut output,
                    text(json_field(span, "parent_span_id", "parentSpanId")),
                );
                let span_id = text(json_field(span, "span_id", "spanId"));
                let parent_id = text(json_field(span, "parent_span_id", "parentSpanId"));
                let id_count = span_index.get(span_id).map(|entry| entry.0).unwrap_or(0);
                let (parent_class, parent_trace_matches) = if parent_id.is_empty() {
                    ("root", true)
                } else if let Some((_, parent_trace)) = span_index.get(parent_id) {
                    (
                        "child",
                        parent_trace == text(json_field(span, "trace_id", "traceId")),
                    )
                } else {
                    ("external", true)
                };
                write!(output, ") (id-count {id_count}) (parent-class {parent_class}) (parent-trace-matches {}) (trace-state ", if parent_trace_matches { "#t" } else { "#f" }).unwrap();
                string(
                    &mut output,
                    text(json_field(span, "trace_state", "traceState")),
                );
                output.push_str(") (name ");
                string(&mut output, text(span.get("name")));
                write!(
                    output,
                    ") (kind {}) (start {}) (end {}) (attributes ",
                    integer(span.get("kind")),
                    integer(json_field(
                        span,
                        "start_time_unix_nano",
                        "startTimeUnixNano"
                    )),
                    integer(json_field(span, "end_time_unix_nano", "endTimeUnixNano"))
                )
                .unwrap();
                attributes(&mut output, span.get("attributes"));
                write!(
                    output,
                    ") (dropped-attributes {}) (events ",
                    integer(json_field(
                        span,
                        "dropped_attributes_count",
                        "droppedAttributesCount"
                    ))
                )
                .unwrap();
                events(&mut output, span.get("events"));
                write!(
                    output,
                    ") (dropped-events {}) (links ",
                    integer(json_field(
                        span,
                        "dropped_events_count",
                        "droppedEventsCount"
                    ))
                )
                .unwrap();
                links(&mut output, span.get("links"));
                let status = span.get("status").unwrap_or(&Value::Null);
                write!(
                    output,
                    ") (dropped-links {}) (status-code {}) (status-message ",
                    integer(json_field(span, "dropped_links_count", "droppedLinksCount")),
                    integer(status.get("code"))
                )
                .unwrap();
                string(&mut output, text(status.get("message")));
                write!(output, ") (flags {}))\n", integer(span.get("flags"))).unwrap();
            }
        }
    }
    output.push_str("))\n(metrics (\n");
    for (record, payload) in records.iter().zip(&payloads) {
        if record.signal != "metrics" {
            continue;
        }
        for resource in array(json_field(payload, "resource_metrics", "resourceMetrics")) {
            for group in array(json_field(resource, "scope_metrics", "scopeMetrics")) {
                let scope = group.get("scope").unwrap_or(&Value::Null);
                for metric in array(group.get("metrics")) {
                    let (data_type, data_points) = json_metric_data(metric);
                    output.push_str("  ((scope ");
                    string(&mut output, text(scope.get("name")));
                    output.push_str(") (name ");
                    string(&mut output, text(metric.get("name")));
                    write!(
                        output,
                        ") (data-type {data_type}) (data-points {data_points}))\n"
                    )
                    .unwrap();
                }
            }
        }
    }
    output.push_str("))\n(logs (\n");
    for (record, payload) in records.iter().zip(&payloads) {
        if record.signal != "logs" {
            continue;
        }
        for resource in array(json_field(payload, "resource_logs", "resourceLogs")) {
            for group in array(json_field(resource, "scope_logs", "scopeLogs")) {
                let scope = group.get("scope").unwrap_or(&Value::Null);
                for log in array(json_field(group, "log_records", "logRecords")) {
                    output.push_str("  ((scope ");
                    string(&mut output, text(scope.get("name")));
                    write!(
                        output,
                        ") (time {}) (observed-time {}) (severity-number {}) (severity-text ",
                        integer(json_field(log, "time_unix_nano", "timeUnixNano")),
                        integer(json_field(
                            log,
                            "observed_time_unix_nano",
                            "observedTimeUnixNano"
                        )),
                        integer(json_field(log, "severity_number", "severityNumber"))
                    )
                    .unwrap();
                    string(
                        &mut output,
                        text(json_field(log, "severity_text", "severityText")),
                    );
                    output.push_str(") (body ");
                    any_value(&mut output, log.get("body"));
                    output.push_str(") (attributes ");
                    attributes(&mut output, log.get("attributes"));
                    write!(
                        output,
                        ") (dropped-attributes {}) (flags {}) (trace-id ",
                        integer(json_field(
                            log,
                            "dropped_attributes_count",
                            "droppedAttributesCount"
                        )),
                        integer(log.get("flags"))
                    )
                    .unwrap();
                    string(&mut output, text(json_field(log, "trace_id", "traceId")));
                    output.push_str(") (span-id ");
                    string(&mut output, text(json_field(log, "span_id", "spanId")));
                    output.push_str(") (event-name ");
                    string(
                        &mut output,
                        text(json_field(log, "event_name", "eventName")),
                    );
                    output.push_str("))\n");
                }
            }
        }
    }
    output.push_str(")))\n");
    Ok(output.into_bytes())
}

fn span_index(payloads: &[Value]) -> BTreeMap<String, (usize, String)> {
    let mut index = BTreeMap::<String, (usize, String)>::new();
    for payload in payloads {
        for group in trace_groups(payload) {
            for span in array(group.get("spans")) {
                let span_id = text(json_field(span, "span_id", "spanId"));
                index
                    .entry(span_id.into())
                    .and_modify(|entry| entry.0 += 1)
                    .or_insert((1, text(json_field(span, "trace_id", "traceId")).into()));
            }
        }
    }
    index
}

struct Bucket {
    count: usize,
    scope: String,
    kind: &'static str,
    status: &'static str,
    name_matcher: String,
    parent: &'static str,
    http_status: Option<i64>,
}

pub fn golden_candidate(records: &[Record], app: &str) -> Result<Vec<u8>, String> {
    let payloads = records
        .iter()
        .filter(|record| record.signal == "traces")
        .map(|record| {
            serde_json::to_value(&record.payload)
                .map_err(|error| format!("serialize trace payload for golden: {error}"))
        })
        .collect::<Result<Vec<_>, _>>()?;
    let mut span_traces = BTreeMap::<String, String>::new();
    for payload in &payloads {
        for group in trace_groups(payload) {
            for span in array(group.get("spans")) {
                let span_id = text(json_field(span, "span_id", "spanId"));
                if span_id.is_empty()
                    || span_traces
                        .insert(
                            span_id.into(),
                            text(json_field(span, "trace_id", "traceId")).into(),
                        )
                        .is_some()
                {
                    return Err(format!("missing or duplicate span ID {span_id:?}"));
                }
            }
        }
    }
    let mut buckets = BTreeMap::<String, Bucket>::new();
    let mut saw_span = false;
    for payload in &payloads {
        for group in trace_groups(payload) {
            let scope_name = text(group.get("scope").and_then(|scope| scope.get("name")));
            let scope = scope_alias(app, scope_name)?;
            for span in array(group.get("spans")) {
                saw_span = true;
                let kind = enum_name(
                    integer(span.get("kind")),
                    &[
                        "unspecified",
                        "internal",
                        "server",
                        "client",
                        "producer",
                        "consumer",
                    ],
                    "span kind",
                )?;
                if kind == "server" {
                    continue;
                }
                let status = enum_name(
                    integer(span.get("status").and_then(|status| status.get("code"))),
                    &["unset", "ok", "error"],
                    "span status",
                )?;
                let parent_id = text(json_field(span, "parent_span_id", "parentSpanId"));
                let parent = if parent_id.is_empty() {
                    "root"
                } else if let Some(trace_id) = span_traces.get(parent_id) {
                    if trace_id != text(json_field(span, "trace_id", "traceId")) {
                        return Err("span parent belongs to another trace".into());
                    }
                    "child"
                } else {
                    "external"
                };
                let matcher = name_matcher(app, &scope, text(span.get("name")));
                let http_status = integer_attribute(span.get("attributes"), "http.status_code")?;
                let key = format!(
                    "{scope}\u{1f}{kind}\u{1f}{status}\u{1f}{matcher}\u{1f}{parent}\u{1f}{http_status:?}"
                );
                buckets
                    .entry(key)
                    .and_modify(|bucket| bucket.count += 1)
                    .or_insert(Bucket {
                        count: 1,
                        scope: scope.clone(),
                        kind,
                        status,
                        name_matcher: matcher,
                        parent,
                        http_status,
                    });
            }
        }
    }
    if !saw_span {
        return Err("trace capture contains no spans".into());
    }
    let mut output = String::from("(define expected-implementation-buckets\n  '(\n");
    for bucket in buckets.values() {
        write!(
            output,
            "    ({} {} {} {} {} {} ",
            bucket.count,
            bucket.scope,
            bucket.kind,
            bucket.status,
            bucket.name_matcher,
            bucket.parent
        )
        .unwrap();
        match bucket.http_status {
            Some(status) => write!(output, "{status}").unwrap(),
            None => output.push_str("absent"),
        }
        output.push_str(")\n");
    }
    output.push_str("  ))\n");
    Ok(output.into_bytes())
}

fn scope_alias(app: &str, scope: &str) -> Result<String, String> {
    match (app, scope) {
        ("aiohttp", "opentelemetry.instrumentation.sqlite3") => Ok("sqlite".into()),
        ("aiohttp", "opentelemetry.instrumentation.sqlalchemy") => Ok("sqlalchemy".into()),
        ("aiohttp", "opentelemetry.instrumentation.aiohttp_server") => Ok("http".into()),
        ("django", "opentelemetry.instrumentation.sqlite3") => Ok("sqlite".into()),
        ("django", "opentelemetry.instrumentation.django") => Ok("django".into()),
        _ if scope.is_empty() => Err(format!("empty instrumentation scope for {app}")),
        _ => Ok(generic_scope_alias(scope)),
    }
}

fn generic_scope_alias(scope: &str) -> String {
    let mut alias = String::from("scope-");
    let mut previous_separator = false;
    for character in scope.chars() {
        if character.is_ascii_alphanumeric() {
            alias.push(character.to_ascii_lowercase());
            previous_separator = false;
        } else if !previous_separator {
            alias.push('-');
            previous_separator = true;
        }
    }
    while alias.ends_with('-') {
        alias.pop();
    }
    alias
}

fn enum_name(value: i64, names: &[&'static str], label: &str) -> Result<&'static str, String> {
    names
        .get(usize::try_from(value).unwrap_or(usize::MAX))
        .copied()
        .ok_or_else(|| format!("invalid {label} {value}"))
}

fn name_matcher(app: &str, scope: &str, name: &str) -> String {
    if app == "aiohttp" && scope == "sqlalchemy" && name.ends_with("realworld.sqlite3") {
        if let Some((operation, _)) = name.split_once(" /") {
            let mut output = String::from("(prefix-suffix ");
            string(&mut output, &format!("{operation} /"));
            output.push(' ');
            string(&mut output, "realworld.sqlite3");
            output.push(')');
            return output;
        }
    }
    let mut output = String::from("(exact ");
    string(&mut output, name);
    output.push(')');
    output
}

fn integer_attribute(
    attributes_value: Option<&Value>,
    wanted: &str,
) -> Result<Option<i64>, String> {
    let mut result = None;
    for attribute in array(attributes_value) {
        if text(attribute.get("key")) != wanted {
            continue;
        }
        if result.is_some() {
            return Err(format!("duplicate attribute {wanted:?}"));
        }
        result = attribute
            .get("value")
            .map(|value| value.get("value").unwrap_or(value))
            .and_then(|value| json_field(value, "int_value", "intValue"))
            .map(|value| integer(Some(value)));
        if result.is_none() {
            return Err(format!("attribute {wanted:?} is not an integer"));
        }
    }
    Ok(result)
}

fn trace_payloads<'a>(
    records: &'a [Record],
    payloads: &'a [Value],
) -> impl Iterator<Item = &'a Value> {
    records
        .iter()
        .zip(payloads)
        .filter(|(record, _)| record.signal == "traces")
        .map(|(_, payload)| payload)
}

fn resources<'a>(payload: &'a Value, signal: &str) -> Vec<&'a Value> {
    let (snake, camel) = match signal {
        "traces" => ("resource_spans", "resourceSpans"),
        "metrics" => ("resource_metrics", "resourceMetrics"),
        "logs" => ("resource_logs", "resourceLogs"),
        _ => return Vec::new(),
    };
    array(json_field(payload, snake, camel))
        .iter()
        .map(|item| item.get("resource").unwrap_or(&Value::Null))
        .collect()
}

fn json_metric_data(metric: &Value) -> (&'static str, usize) {
    let data = metric.get("data").unwrap_or(metric);
    for (name, snake, camel) in [
        ("gauge", "gauge", "gauge"),
        ("sum", "sum", "sum"),
        ("histogram", "histogram", "histogram"),
        (
            "exponential-histogram",
            "exponential_histogram",
            "exponentialHistogram",
        ),
        ("summary", "summary", "summary"),
    ] {
        if let Some(value) = json_field(data, snake, camel) {
            return (name, length(json_field(value, "data_points", "dataPoints")));
        }
    }
    ("missing", 0)
}

fn trace_groups(payload: &Value) -> Vec<&Value> {
    array(json_field(payload, "resource_spans", "resourceSpans"))
        .iter()
        .flat_map(|resource| array(json_field(resource, "scope_spans", "scopeSpans")))
        .collect()
}

fn attributes(output: &mut String, value: Option<&Value>) {
    output.push('(');
    for attribute in array(value) {
        output.push('(');
        string(output, text(attribute.get("key")));
        output.push(' ');
        any_value(output, attribute.get("value"));
        output.push(')');
    }
    output.push(')');
}

fn any_value(output: &mut String, value: Option<&Value>) {
    let value = value
        .map(|value| value.get("value").unwrap_or(value))
        .unwrap_or(&Value::Null);
    if let Some(value) = json_field(value, "string_value", "stringValue").and_then(Value::as_str) {
        if value.len() > 256 {
            write!(output, "(long-string {})", value.len()).unwrap();
        } else {
            output.push_str("(string ");
            string(output, value);
            output.push(')');
        }
    } else if let Some(value) = json_field(value, "int_value", "intValue") {
        write!(output, "(integer {})", integer(Some(value))).unwrap();
    } else if let Some(value) =
        json_field(value, "bool_value", "boolValue").and_then(Value::as_bool)
    {
        output.push_str(if value {
            "(boolean #t)"
        } else {
            "(boolean #f)"
        });
    } else if let Some(value) =
        json_field(value, "double_value", "doubleValue").and_then(Value::as_f64)
    {
        output.push_str("(double ");
        string(output, &format!("{value}"));
        output.push(')');
    } else if let Some(value) = json_field(value, "bytes_value", "bytesValue") {
        output.push_str("(bytes (");
        for byte in value
            .as_array()
            .into_iter()
            .flatten()
            .filter_map(Value::as_u64)
        {
            write!(output, "{byte} ").unwrap();
        }
        output.push_str("))");
    } else {
        output.push_str("(other)");
    }
}

fn events(output: &mut String, value: Option<&Value>) {
    output.push('(');
    for event in array(value) {
        output.push_str("((name ");
        string(output, text(event.get("name")));
        write!(
            output,
            ") (time {}) (dropped-attributes {}) (attributes ",
            integer(json_field(event, "time_unix_nano", "timeUnixNano")),
            integer(json_field(
                event,
                "dropped_attributes_count",
                "droppedAttributesCount"
            ))
        )
        .unwrap();
        attributes(output, event.get("attributes"));
        output.push_str("))");
    }
    output.push(')');
}

fn links(output: &mut String, value: Option<&Value>) {
    output.push('(');
    for link in array(value) {
        output.push_str("((trace-id ");
        string(output, text(json_field(link, "trace_id", "traceId")));
        output.push_str(") (span-id ");
        string(output, text(json_field(link, "span_id", "spanId")));
        write!(
            output,
            ") (dropped-attributes {}) (flags {}))",
            integer(json_field(
                link,
                "dropped_attributes_count",
                "droppedAttributesCount"
            )),
            integer(link.get("flags"))
        )
        .unwrap();
    }
    output.push(')');
}

fn string(output: &mut String, value: &str) {
    output.push('"');
    for character in value.chars() {
        match character {
            '"' => output.push_str("\\\""),
            '\\' => output.push_str("\\\\"),
            '\n' => output.push_str("\\n"),
            '\r' => output.push_str("\\r"),
            '\t' => output.push_str("\\t"),
            _ => output.push(character),
        }
    }
    output.push('"');
}

fn array(value: Option<&Value>) -> &[Value] {
    value
        .and_then(Value::as_array)
        .map(Vec::as_slice)
        .unwrap_or(&[])
}

fn text(value: Option<&Value>) -> &str {
    value.and_then(Value::as_str).unwrap_or("")
}

fn integer(value: Option<&Value>) -> i64 {
    value
        .and_then(|value| {
            value
                .as_i64()
                .or_else(|| value.as_str().and_then(|value| value.parse().ok()))
        })
        .unwrap_or(0)
}

fn json_field<'a>(value: &'a Value, snake: &str, camel: &str) -> Option<&'a Value> {
    value.get(snake).or_else(|| value.get(camel))
}

fn length(value: Option<&Value>) -> usize {
    array(value).len()
}
