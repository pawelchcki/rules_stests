use crate::data::{Payload, Record};
use crate::otlp_json;
use crate::proto;
use crate::trace_forest::{self, Forest, Group, Node, Trace};
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
    let mut span_index = BTreeMap::<(String, String), usize>::new();
    let mut span_parents = BTreeMap::<(String, String), String>::new();
    for record in records {
        if let Payload::Traces(payload) = &record.payload {
            for resource in &payload.resource_spans {
                for group in &resource.scope_spans {
                    for span in &group.spans {
                        let span_id = hex_text(&span.span_id);
                        let trace_id = hex_text(&span.trace_id);
                        span_index
                            .entry((trace_id.clone(), span_id.clone()))
                            .and_modify(|count| *count += 1)
                            .or_insert(1);
                        span_parents
                            .entry((trace_id, span_id))
                            .or_insert_with(|| hex_text(&span.parent_span_id));
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
                    write_typed_resource(
                        &mut output,
                        &record.signal,
                        item.resource.as_ref(),
                        &item.schema_url,
                    );
                }
            }
            Payload::Metrics(payload) => {
                for item in &payload.resource_metrics {
                    write_typed_resource(
                        &mut output,
                        &record.signal,
                        item.resource.as_ref(),
                        &item.schema_url,
                    );
                }
            }
            Payload::Logs(payload) => {
                for item in &payload.resource_logs {
                    write_typed_resource(
                        &mut output,
                        &record.signal,
                        item.resource.as_ref(),
                        &item.schema_url,
                    );
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
                        ") (dropped-attributes {}) (schema-url ",
                        scope
                            .map(|scope| scope.dropped_attributes_count)
                            .unwrap_or(0)
                    )
                    .unwrap();
                    string(&mut output, &group.schema_url);
                    output.push_str("))\n");
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
                        write_typed_span(&mut output, scope_name, span, &span_index, &span_parents);
                    }
                }
            }
        }
    }
    output.push_str("))\n(trace-shapes ");
    write_trace_forest(&mut output, &trace_forest::from_records(records)?, None);
    output.push_str(")\n(metrics (\n");
    for record in records {
        if let Payload::Metrics(payload) = &record.payload {
            for resource in &payload.resource_metrics {
                for group in &resource.scope_metrics {
                    let scope = group.scope.as_ref();
                    for metric in &group.metrics {
                        let (
                            data_type,
                            data_points,
                            data_points_valid,
                            aggregation_temporality,
                            monotonic,
                        ) = typed_metric_data(metric);
                        let point_summary = typed_metric_point_summary(metric);
                        output.push_str("  ((scope ");
                        string(
                            &mut output,
                            scope.map(|scope| scope.name.as_str()).unwrap_or(""),
                        );
                        output.push_str(") (scope-version ");
                        string(
                            &mut output,
                            scope.map(|scope| scope.version.as_str()).unwrap_or(""),
                        );
                        output.push_str(") (scope-attributes ");
                        typed_attributes(
                            &mut output,
                            scope
                                .map(|scope| scope.attributes.as_slice())
                                .unwrap_or(&[]),
                        );
                        output.push_str(") (schema-url ");
                        string(&mut output, &group.schema_url);
                        output.push_str(") (name ");
                        string(&mut output, &metric.name);
                        output.push_str(") (description ");
                        string(&mut output, &metric.description);
                        output.push_str(") (unit ");
                        string(&mut output, &metric.unit);
                        output.push_str(") (metadata ");
                        typed_attributes(&mut output, &metric.metadata);
                        write!(
                            output,
                            ") (scope-dropped-attributes {}) (data-type {data_type}) (aggregation-temporality {aggregation_temporality}) (monotonic {monotonic}) (data-points {data_points}) (data-points-valid {}) (exemplars {}) (exemplars-with-trace-context {}) (exemplars-with-time {}) (points-with-start {}) (points-start-le-time {}) (point-attributes ",
                            scope
                                .map(|scope| scope.dropped_attributes_count)
                                .unwrap_or(0),
                            if data_points_valid { "#t" } else { "#f" },
                            point_summary.exemplars,
                            point_summary.exemplars_with_trace_context,
                            point_summary.exemplars_with_time,
                            point_summary.start_present,
                            point_summary.start_le_time
                        )
                        .unwrap();
                        typed_metric_point_attributes(&mut output, metric);
                        output.push_str("))\n");
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
                    let scope = group.scope.as_ref();
                    for log in &group.log_records {
                        output.push_str("  ((scope ");
                        string(
                            &mut output,
                            scope.map(|scope| scope.name.as_str()).unwrap_or(""),
                        );
                        output.push_str(") (scope-version ");
                        string(
                            &mut output,
                            scope.map(|scope| scope.version.as_str()).unwrap_or(""),
                        );
                        output.push_str(") (scope-attributes ");
                        typed_attributes(
                            &mut output,
                            scope
                                .map(|scope| scope.attributes.as_slice())
                                .unwrap_or(&[]),
                        );
                        output.push_str(") (schema-url ");
                        string(&mut output, &group.schema_url);
                        write!(
                            output,
                            ") (scope-dropped-attributes {}) (time {}) (observed-time {}) (severity-number {}) (severity-text ",
                            scope
                                .map(|scope| scope.dropped_attributes_count)
                                .unwrap_or(0),
                            log.time_unix_nano,
                            log.observed_time_unix_nano,
                            log.severity_number
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
    output.push_str(
        "))\n(json-field-spellings-valid #t)\n(json-collections-valid #t)\n(json-strings-valid #t))\n",
    );
    Ok(output.into_bytes())
}

/// Aggregates over a metric's data points that the Scheme contract needs but
/// could not afford to read point by point: a large scenario carries thousands
/// of points, and the capture has a size budget.
pub struct MetricPointSummary {
    pub exemplars: usize,
    pub exemplars_with_trace_context: usize,
    pub exemplars_with_time: usize,
    pub start_present: usize,
    pub start_le_time: usize,
}

fn summarize_exemplars(summary: &mut MetricPointSummary, exemplars: &[proto::Exemplar]) {
    for exemplar in exemplars {
        summary.exemplars += 1;
        if exemplar.trace_id.len() == 16
            && exemplar.span_id.len() == 8
            && exemplar.trace_id.iter().any(|byte| *byte != 0)
            && exemplar.span_id.iter().any(|byte| *byte != 0)
        {
            summary.exemplars_with_trace_context += 1;
        }
        if exemplar.time_unix_nano > 0 {
            summary.exemplars_with_time += 1;
        }
    }
}

fn summarize_window(summary: &mut MetricPointSummary, start: u64, time: u64) {
    if start == 0 {
        return;
    }
    summary.start_present += 1;
    if start <= time {
        summary.start_le_time += 1;
    }
}

fn typed_metric_point_summary(metric: &proto::Metric) -> MetricPointSummary {
    let mut summary = MetricPointSummary {
        exemplars: 0,
        exemplars_with_trace_context: 0,
        exemplars_with_time: 0,
        start_present: 0,
        start_le_time: 0,
    };
    match metric.data.as_ref() {
        Some(proto::metric::Data::Gauge(data)) => {
            for point in &data.data_points {
                summarize_exemplars(&mut summary, &point.exemplars);
                summarize_window(&mut summary, point.start_time_unix_nano, point.time_unix_nano);
            }
        }
        Some(proto::metric::Data::Sum(data)) => {
            for point in &data.data_points {
                summarize_exemplars(&mut summary, &point.exemplars);
                summarize_window(&mut summary, point.start_time_unix_nano, point.time_unix_nano);
            }
        }
        Some(proto::metric::Data::Histogram(data)) => {
            for point in &data.data_points {
                summarize_exemplars(&mut summary, &point.exemplars);
                summarize_window(&mut summary, point.start_time_unix_nano, point.time_unix_nano);
            }
        }
        Some(proto::metric::Data::ExponentialHistogram(data)) => {
            for point in &data.data_points {
                summarize_exemplars(&mut summary, &point.exemplars);
                summarize_window(&mut summary, point.start_time_unix_nano, point.time_unix_nano);
            }
        }
        _ => {}
    }
    summary
}

fn typed_metric_data(
    metric: &proto::Metric,
) -> (&'static str, usize, bool, &'static str, &'static str) {
    match metric.data.as_ref() {
        Some(proto::metric::Data::Gauge(data)) => (
            "gauge",
            data.data_points.len(),
            data.data_points.iter().all(typed_number_point_valid),
            "absent",
            "absent",
        ),
        Some(proto::metric::Data::Sum(data)) => (
            "sum",
            data.data_points.len(),
            aggregation_temporality_valid(data.aggregation_temporality)
                && data.data_points.iter().all(typed_number_point_valid),
            aggregation_temporality_name(data.aggregation_temporality),
            if data.is_monotonic { "#t" } else { "#f" },
        ),
        Some(proto::metric::Data::Histogram(data)) => (
            "histogram",
            data.data_points.len(),
            aggregation_temporality_valid(data.aggregation_temporality)
                && data.data_points.iter().all(typed_histogram_point_valid),
            aggregation_temporality_name(data.aggregation_temporality),
            "absent",
        ),
        Some(proto::metric::Data::ExponentialHistogram(data)) => (
            "exponential-histogram",
            data.data_points.len(),
            aggregation_temporality_valid(data.aggregation_temporality)
                && data
                    .data_points
                    .iter()
                    .all(typed_exponential_histogram_point_valid),
            aggregation_temporality_name(data.aggregation_temporality),
            "absent",
        ),
        Some(proto::metric::Data::Summary(data)) => (
            "summary",
            data.data_points.len(),
            data.data_points.iter().all(typed_summary_point_valid),
            "absent",
            "absent",
        ),
        None => ("missing", 0, false, "absent", "absent"),
    }
}

fn typed_metric_point_attributes(output: &mut String, metric: &proto::Metric) {
    output.push('(');
    match metric.data.as_ref() {
        Some(proto::metric::Data::Gauge(data)) => {
            for point in &data.data_points {
                typed_attributes(output, &point.attributes);
            }
        }
        Some(proto::metric::Data::Sum(data)) => {
            for point in &data.data_points {
                typed_attributes(output, &point.attributes);
            }
        }
        Some(proto::metric::Data::Histogram(data)) => {
            for point in &data.data_points {
                typed_attributes(output, &point.attributes);
            }
        }
        Some(proto::metric::Data::ExponentialHistogram(data)) => {
            for point in &data.data_points {
                typed_attributes(output, &point.attributes);
            }
        }
        Some(proto::metric::Data::Summary(data)) => {
            for point in &data.data_points {
                typed_attributes(output, &point.attributes);
            }
        }
        None => {}
    }
    output.push(')');
}

fn aggregation_temporality_valid(value: i32) -> bool {
    matches!(value, 1 | 2)
}

fn aggregation_temporality_name(value: i32) -> &'static str {
    match value {
        1 => "delta",
        2 => "cumulative",
        _ => "invalid",
    }
}

fn typed_point_metadata_valid(
    attributes: &[proto::KeyValue],
    start: u64,
    time: u64,
    flags: u32,
) -> bool {
    time > 0 && start <= time && matches!(flags, 0 | 1) && typed_key_values_valid(attributes)
}

fn typed_number_point_valid(point: &proto::NumberDataPoint) -> bool {
    typed_point_metadata_valid(
        &point.attributes,
        point.start_time_unix_nano,
        point.time_unix_nano,
        point.flags,
    ) && typed_exemplars_valid(&point.exemplars)
        && (point.flags == 1 || point.value.is_some())
}

fn typed_histogram_point_valid(point: &proto::HistogramDataPoint) -> bool {
    typed_point_metadata_valid(
        &point.attributes,
        point.start_time_unix_nano,
        point.time_unix_nano,
        point.flags,
    ) && typed_exemplars_valid(&point.exemplars)
        && (point.flags == 1
            || (point.bucket_counts.len() == point.explicit_bounds.len().saturating_add(1)
                && finite_strictly_increasing(&point.explicit_bounds)
                && typed_extrema_valid(point.min, point.max)
                && point
                    .bucket_counts
                    .iter()
                    .try_fold(0_u64, |total, value| total.checked_add(*value))
                    == Some(point.count)))
}

fn finite_strictly_increasing(values: &[f64]) -> bool {
    values.iter().all(|value| value.is_finite()) && values.windows(2).all(|pair| pair[0] < pair[1])
}

fn typed_exponential_histogram_point_valid(point: &proto::ExponentialHistogramDataPoint) -> bool {
    let bucket_count = point
        .positive
        .iter()
        .chain(point.negative.iter())
        .flat_map(|buckets| buckets.bucket_counts.iter())
        .copied()
        .try_fold(0_u64, u64::checked_add);
    typed_point_metadata_valid(
        &point.attributes,
        point.start_time_unix_nano,
        point.time_unix_nano,
        point.flags,
    ) && typed_exemplars_valid(&point.exemplars)
        && (point.flags == 1
            || ((-10..=20).contains(&point.scale)
                && point.zero_threshold.is_finite()
                && point.zero_threshold >= 0.0
                && typed_extrema_valid(point.min, point.max)
                && bucket_count.and_then(|count| count.checked_add(point.zero_count))
                    == Some(point.count)))
}

fn typed_extrema_valid(min: Option<f64>, max: Option<f64>) -> bool {
    min.is_none_or(f64::is_finite)
        && max.is_none_or(f64::is_finite)
        && match (min, max) {
            (Some(min), Some(max)) => min <= max,
            _ => true,
        }
}

fn typed_exemplars_valid(exemplars: &[proto::Exemplar]) -> bool {
    exemplars.iter().all(|exemplar| {
        let context_valid = (exemplar.trace_id.is_empty() && exemplar.span_id.is_empty())
            || (exemplar.trace_id.len() == 16
                && exemplar.trace_id.iter().any(|byte| *byte != 0)
                && exemplar.span_id.len() == 8
                && exemplar.span_id.iter().any(|byte| *byte != 0));
        exemplar.time_unix_nano > 0
            && exemplar.value.is_some()
            && context_valid
            && typed_key_values_valid(&exemplar.filtered_attributes)
    })
}

fn typed_summary_point_valid(point: &proto::SummaryDataPoint) -> bool {
    typed_point_metadata_valid(
        &point.attributes,
        point.start_time_unix_nano,
        point.time_unix_nano,
        point.flags,
    ) && (point.flags == 1
        || quantiles_strictly_increasing(point.quantile_values.iter().map(|value| value.quantile)))
}

fn quantiles_strictly_increasing(mut quantiles: impl Iterator<Item = f64>) -> bool {
    let mut previous = None;
    quantiles.all(|quantile| {
        let valid =
            (0.0..=1.0).contains(&quantile) && previous.is_none_or(|previous| previous < quantile);
        previous = Some(quantile);
        valid
    })
}

fn typed_key_values_valid(values: &[proto::KeyValue]) -> bool {
    values.iter().enumerate().all(|(index, item)| {
        !item.key.is_empty()
            && typed_any_value_valid(item.value.as_ref())
            && !values[..index]
                .iter()
                .any(|previous| previous.key == item.key)
    })
}

fn typed_any_value_valid(value: Option<&proto::AnyValue>) -> bool {
    match value.and_then(|value| value.value.as_ref()) {
        Some(proto::any_value::Value::ArrayValue(value)) => value
            .values
            .iter()
            .all(|item| typed_any_value_valid(Some(item))),
        Some(proto::any_value::Value::KvlistValue(value)) => typed_key_values_valid(&value.values),
        Some(_) => true,
        None => false,
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

fn write_typed_resource(
    output: &mut String,
    signal: &str,
    resource: Option<&proto::Resource>,
    schema_url: &str,
) {
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
        ") (dropped-attributes {}) (entity-refs {}) (schema-url ",
        resource
            .map(|resource| resource.dropped_attributes_count)
            .unwrap_or(0),
        resource
            .map(|resource| resource.entity_refs.len())
            .unwrap_or(0)
    )
    .unwrap();
    string(output, schema_url);
    output.push_str("))\n");
}

fn write_typed_span(
    output: &mut String,
    scope: &str,
    span: &proto::Span,
    index: &BTreeMap<(String, String), usize>,
    parents: &BTreeMap<(String, String), String>,
) {
    let trace_id = hex_text(&span.trace_id);
    let span_id = hex_text(&span.span_id);
    let parent_id = hex_text(&span.parent_span_id);
    let parent_valid = parent_topology_valid(&trace_id, &span_id, parents);
    let id_count = index
        .get(&(trace_id.clone(), span_id.clone()))
        .copied()
        .unwrap_or(0);
    let parent_class = if !parent_valid {
        "invalid"
    } else if parent_id.is_empty() {
        "root"
    } else if index.contains_key(&(trace_id.clone(), parent_id.clone())) {
        "child"
    } else {
        "external"
    };
    output.push_str("  ((scope ");
    string(output, scope);
    output.push_str(") (trace-id ");
    string(output, &trace_id);
    output.push_str(") (span-id ");
    string(output, &span_id);
    output.push_str(") (parent-span-id ");
    string(output, &parent_id);
    write!(
        output,
        ") (id-count {id_count}) (parent-class {parent_class}) (parent-valid {}) (trace-state ",
        if parent_valid { "#t" } else { "#f" }
    )
    .unwrap();
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
            string(output, &double_text(*value));
            output.push(')');
        }
        Some(proto::any_value::Value::BytesValue(value)) => {
            output.push_str("(bytes (");
            for byte in value {
                write!(output, "{byte} ").unwrap();
            }
            output.push_str("))");
        }
        Some(proto::any_value::Value::ArrayValue(value)) => {
            output.push_str("(array (");
            for item in &value.values {
                typed_any_value(output, Some(item));
                output.push(' ');
            }
            output.push_str("))");
        }
        Some(proto::any_value::Value::KvlistValue(value)) => {
            output.push_str("(kvlist (");
            for item in &value.values {
                output.push('(');
                string(output, &item.key);
                output.push(' ');
                typed_any_value(output, item.value.as_ref());
                output.push(')');
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
    let field_spellings_valid = !payloads.iter().any(has_duplicate_json_field_spellings);
    let collections_valid = !payloads.iter().any(has_malformed_json_collection);
    let strings_valid = !payloads.iter().any(has_malformed_json_string);
    let span_index = span_index(&payloads);
    let span_parents = span_parents(&payloads);
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
        for wrapper in resource_wrappers(payload, &record.signal) {
            let resource = wrapper.get("resource").unwrap_or(&Value::Null);
            output.push_str("  ((signal ");
            output.push_str(&record.signal);
            output.push_str(") (attributes ");
            attributes(&mut output, resource.get("attributes"));
            write!(
                output,
                ") (dropped-attributes {}) (entity-refs {}) (schema-url ",
                integer(json_field(
                    resource,
                    "dropped_attributes_count",
                    "droppedAttributesCount"
                )),
                length(json_field(resource, "entity_refs", "entityRefs"))
            )
            .unwrap();
            string(
                &mut output,
                text(json_field(wrapper, "schema_url", "schemaUrl")),
            );
            output.push_str("))\n");
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
                ") (dropped-attributes {}) (schema-url ",
                integer(json_field(
                    scope,
                    "dropped_attributes_count",
                    "droppedAttributesCount"
                ))
            )
            .unwrap();
            string(
                &mut output,
                text(json_field(group, "schema_url", "schemaUrl")),
            );
            output.push_str("))\n");
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
                let trace_id = text(json_field(span, "trace_id", "traceId"));
                let parent_valid = parent_topology_valid(trace_id, span_id, &span_parents);
                let id_count = span_index
                    .get(&span_key(trace_id, span_id))
                    .copied()
                    .unwrap_or(0);
                let parent_class = if !parent_valid {
                    "invalid"
                } else if parent_id.is_empty() {
                    "root"
                } else if span_index.contains_key(&span_key(trace_id, parent_id)) {
                    "child"
                } else {
                    "external"
                };
                write!(output, ") (id-count {id_count}) (parent-class {parent_class}) (parent-valid {}) (trace-state ", if parent_valid { "#t" } else { "#f" }).unwrap();
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
    output.push_str("))\n(trace-shapes ");
    write_trace_forest(&mut output, &trace_forest::from_records(records)?, None);
    output.push_str(")\n(metrics (\n");
    for (record, payload) in records.iter().zip(&payloads) {
        if record.signal != "metrics" {
            continue;
        }
        for resource in array(json_field(payload, "resource_metrics", "resourceMetrics")) {
            for group in array(json_field(resource, "scope_metrics", "scopeMetrics")) {
                let scope = group.get("scope").unwrap_or(&Value::Null);
                for metric in array(group.get("metrics")) {
                    let (
                        data_type,
                        data_points,
                        data_points_valid,
                        aggregation_temporality,
                        monotonic,
                    ) = json_metric_data(metric);
                    let point_summary = json_metric_point_summary(metric);
                    output.push_str("  ((scope ");
                    string(&mut output, text(scope.get("name")));
                    output.push_str(") (scope-version ");
                    string(&mut output, text(scope.get("version")));
                    output.push_str(") (scope-attributes ");
                    attributes(&mut output, scope.get("attributes"));
                    output.push_str(") (schema-url ");
                    string(
                        &mut output,
                        text(json_field(group, "schema_url", "schemaUrl")),
                    );
                    output.push_str(") (name ");
                    string(&mut output, text(metric.get("name")));
                    output.push_str(") (description ");
                    string(&mut output, text(metric.get("description")));
                    output.push_str(") (unit ");
                    string(&mut output, text(metric.get("unit")));
                    output.push_str(") (metadata ");
                    attributes(&mut output, metric.get("metadata"));
                    write!(
                        output,
                        ") (scope-dropped-attributes {}) (data-type {data_type}) (aggregation-temporality {aggregation_temporality}) (monotonic {monotonic}) (data-points {data_points}) (data-points-valid {}) (exemplars {}) (exemplars-with-trace-context {}) (exemplars-with-time {}) (points-with-start {}) (points-start-le-time {}) (point-attributes ",
                        integer(json_field(
                            scope,
                            "dropped_attributes_count",
                            "droppedAttributesCount"
                        )),
                        if data_points_valid { "#t" } else { "#f" },
                        point_summary.exemplars,
                        point_summary.exemplars_with_trace_context,
                        point_summary.exemplars_with_time,
                        point_summary.start_present,
                        point_summary.start_le_time
                    )
                    .unwrap();
                    json_metric_point_attributes(&mut output, metric);
                    output.push_str("))\n");
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
                    output.push_str(") (scope-version ");
                    string(&mut output, text(scope.get("version")));
                    output.push_str(") (scope-attributes ");
                    attributes(&mut output, scope.get("attributes"));
                    output.push_str(") (schema-url ");
                    string(
                        &mut output,
                        text(json_field(group, "schema_url", "schemaUrl")),
                    );
                    write!(
                        output,
                        ") (scope-dropped-attributes {}) (time {}) (observed-time {}) (severity-number {}) (severity-text ",
                        integer(json_field(
                            scope,
                            "dropped_attributes_count",
                            "droppedAttributesCount"
                        )),
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
    write!(
        output,
        "))\n(json-field-spellings-valid {})\n(json-collections-valid {})\n(json-strings-valid {}))\n",
        if field_spellings_valid { "#t" } else { "#f" },
        if collections_valid { "#t" } else { "#f" },
        if strings_valid { "#t" } else { "#f" }
    )
    .unwrap();
    Ok(output.into_bytes())
}

fn span_index(payloads: &[Value]) -> BTreeMap<(String, String), usize> {
    let mut index = BTreeMap::<(String, String), usize>::new();
    for payload in payloads {
        for group in trace_groups(payload) {
            for span in array(group.get("spans")) {
                let span_id = text(json_field(span, "span_id", "spanId"));
                let trace_id = text(json_field(span, "trace_id", "traceId"));
                index
                    .entry(span_key(trace_id, span_id))
                    .and_modify(|count| *count += 1)
                    .or_insert(1);
            }
        }
    }
    index
}

fn span_parents(payloads: &[Value]) -> BTreeMap<(String, String), String> {
    let mut parents = BTreeMap::new();
    for payload in payloads {
        for group in trace_groups(payload) {
            for span in array(group.get("spans")) {
                let span_id = text(json_field(span, "span_id", "spanId"));
                let trace_id = text(json_field(span, "trace_id", "traceId"));
                let parent_id = text(json_field(span, "parent_span_id", "parentSpanId"));
                parents
                    .entry(span_key(trace_id, span_id))
                    .or_insert_with(|| normalized_id(parent_id));
            }
        }
    }
    parents
}

fn parent_topology_valid(
    trace_id: &str,
    span_id: &str,
    parents: &BTreeMap<(String, String), String>,
) -> bool {
    let mut seen = Vec::<String>::new();
    let trace_id = normalized_id(trace_id);
    let mut current = normalized_id(span_id);
    loop {
        if seen.iter().any(|span| span == &current) {
            return false;
        }
        seen.push(current.clone());
        let Some(parent) = parents.get(&(trace_id.clone(), current)) else {
            return true;
        };
        if parent.is_empty() {
            return true;
        }
        current = parent.clone();
    }
}

fn normalized_id(value: &str) -> String {
    value.to_ascii_lowercase()
}

fn span_key(trace_id: &str, span_id: &str) -> (String, String) {
    (normalized_id(trace_id), normalized_id(span_id))
}

pub fn scenario_shape_candidate(records: &[Record], app: &str) -> Result<Vec<u8>, String> {
    let payloads = records
        .iter()
        .filter(|record| record.signal == "traces")
        .map(|record| {
            serde_json::to_value(&record.payload)
                .map_err(|error| format!("serialize trace payload for shape: {error}"))
        })
        .collect::<Result<Vec<_>, _>>()?;
    if payloads.iter().any(has_duplicate_json_field_spellings) {
        return Err("duplicate OTLP JSON field spellings".into());
    }
    if payloads.iter().any(has_malformed_json_collection) {
        return Err("malformed OTLP JSON collection".into());
    }
    if payloads.iter().any(has_malformed_json_string) {
        return Err("malformed OTLP JSON string field".into());
    }
    let forest = trace_forest::from_records(records)?;
    if forest.traces.is_empty() {
        return Err("trace capture contains no spans".into());
    }
    let mut output = String::from("(define scenario-shape\n  ");
    write_trace_forest(&mut output, &forest, Some(app));
    output.push_str(")\n");
    Ok(output.into_bytes())
}

fn write_trace_forest(output: &mut String, forest: &Forest, candidate_app: Option<&str>) {
    output.push_str("(traces");
    for trace in &forest.traces {
        output.push('\n');
        write_group(output, trace, 4, candidate_app, write_trace);
    }
    output.push(')');
}

fn write_group<T>(
    output: &mut String,
    group: &Group<T>,
    indent: usize,
    candidate_app: Option<&str>,
    writer: fn(&mut String, &T, usize, Option<&str>),
) {
    spaces(output, indent);
    if group.count > 1 {
        write!(output, "(repeat {} ", group.count).unwrap();
        writer(output, &group.item, indent + 2, candidate_app);
        output.push(')');
    } else {
        writer(output, &group.item, indent, candidate_app);
    }
}

fn write_trace(output: &mut String, trace: &Trace, indent: usize, candidate_app: Option<&str>) {
    output.push_str("(trace (coverage ");
    if candidate_app.is_some() {
        output.push('\'');
    }
    write!(output, "{})\n", trace.coverage.name()).unwrap();
    spaces(output, indent + 2);
    output.push_str("(unordered");
    for root in &trace.roots {
        output.push('\n');
        write_group(output, root, indent + 4, candidate_app, write_node);
    }
    output.push_str("))");
}

fn write_node(output: &mut String, node: &Node, indent: usize, candidate_app: Option<&str>) {
    output.push_str("(span (scope ");
    string(output, &node.span.scope);
    output.push_str(") (kind ");
    if candidate_app.is_some() {
        output.push('\'');
    }
    output.push_str(&node.span.kind);
    output.push_str(") (status ");
    if candidate_app.is_some() {
        output.push('\'');
    }
    output.push_str(&node.span.status);
    output.push_str(") (name ");
    if let Some(app) = candidate_app {
        output.push_str(&name_matcher(app, &node.span.scope, &node.span.name));
    } else if node.span.name.ends_with("realworld.sqlite3") && node.span.name.contains(" /") {
        output.push_str(&name_matcher("aiohttp", &node.span.scope, &node.span.name));
    } else {
        string(output, &node.span.name);
    }
    output.push_str(") (http-status ");
    match node.span.http_status {
        Some(status) => write!(output, "{status}").unwrap(),
        None => {
            if candidate_app.is_some() {
                output.push('\'');
            }
            output.push_str("absent");
        }
    }
    output.push(')');
    if !node.children.is_empty() {
        output.push('\n');
        spaces(output, indent + 2);
        output.push_str("(children (unordered");
        for child in &node.children {
            output.push('\n');
            write_group(output, child, indent + 4, candidate_app, write_node);
        }
        output.push_str("))");
    }
    output.push(')');
}

fn spaces(output: &mut String, count: usize) {
    for _ in 0..count {
        output.push(' ');
    }
}

fn name_matcher(app: &str, scope: &str, name: &str) -> String {
    if app == "aiohttp"
        && (scope == "sqlalchemy" || scope == "opentelemetry.instrumentation.sqlalchemy")
        && name.ends_with("realworld.sqlite3")
    {
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

fn resource_wrappers<'a>(payload: &'a Value, signal: &str) -> Vec<&'a Value> {
    let (snake, camel) = match signal {
        "traces" => ("resource_spans", "resourceSpans"),
        "metrics" => ("resource_metrics", "resourceMetrics"),
        "logs" => ("resource_logs", "resourceLogs"),
        _ => return Vec::new(),
    };
    array(json_field(payload, snake, camel)).iter().collect()
}

/// The JSON mirror of typed_metric_point_summary, so a capture decoded from
/// OTLP/JSON carries the same fields as one decoded from protobuf.
fn json_metric_point_summary(metric: &Value) -> MetricPointSummary {
    let mut summary = MetricPointSummary {
        exemplars: 0,
        exemplars_with_trace_context: 0,
        exemplars_with_time: 0,
        start_present: 0,
        start_le_time: 0,
    };
    let data = metric.get("data").unwrap_or(metric);
    for key in [
        ("gauge", "gauge"),
        ("sum", "sum"),
        ("histogram", "histogram"),
        ("exponential_histogram", "exponentialHistogram"),
    ] {
        let Some(value) = json_non_null_field(data, key.0, key.1) else {
            continue;
        };
        for point in array(json_field(value, "data_points", "dataPoints")) {
            for exemplar in array(json_field(point, "exemplars", "exemplars")) {
                summary.exemplars += 1;
                let trace = text(json_field(exemplar, "trace_id", "traceId"));
                let span = text(json_field(exemplar, "span_id", "spanId"));
                if trace.len() == 32
                    && span.len() == 16
                    && trace.bytes().any(|byte| byte != b'0')
                    && span.bytes().any(|byte| byte != b'0')
                {
                    summary.exemplars_with_trace_context += 1;
                }
                if integer(json_field(exemplar, "time_unix_nano", "timeUnixNano")) > 0 {
                    summary.exemplars_with_time += 1;
                }
            }
            let start = integer(json_field(point, "start_time_unix_nano", "startTimeUnixNano"));
            let time = integer(json_field(point, "time_unix_nano", "timeUnixNano"));
            if start > 0 {
                summary.start_present += 1;
                if start <= time {
                    summary.start_le_time += 1;
                }
            }
        }
    }
    summary
}

fn json_metric_data(metric: &Value) -> (&'static str, usize, bool, &'static str, &'static str) {
    let data = metric.get("data").unwrap_or(metric);
    let mut selected = None;
    for (name, snake, camel, validator) in [
        (
            "gauge",
            "gauge",
            "gauge",
            json_number_point_valid as fn(&Value) -> bool,
        ),
        ("sum", "sum", "sum", json_number_point_valid),
        (
            "histogram",
            "histogram",
            "histogram",
            json_histogram_point_valid,
        ),
        (
            "exponential-histogram",
            "exponential_histogram",
            "exponentialHistogram",
            json_exponential_histogram_point_valid,
        ),
        ("summary", "summary", "summary", json_summary_point_valid),
    ] {
        if let Some(value) = json_non_null_field(data, snake, camel) {
            if selected.is_some() {
                return ("multiple", 0, false, "absent", "absent");
            }
            selected = Some((name, value, validator));
        }
    }
    let Some((name, value, validator)) = selected else {
        return ("missing", 0, false, "absent", "absent");
    };
    let points = array(json_field(value, "data_points", "dataPoints"));
    let temporality = if matches!(name, "sum" | "histogram" | "exponential-histogram") {
        match try_integer(json_field(
            value,
            "aggregation_temporality",
            "aggregationTemporality",
        )) {
            Ok(1) => "delta",
            Ok(2) => "cumulative",
            _ => "invalid",
        }
    } else {
        "absent"
    };
    let monotonic = if name == "sum" {
        if json_field(value, "is_monotonic", "isMonotonic")
            .and_then(Value::as_bool)
            .unwrap_or(false)
        {
            "#t"
        } else {
            "#f"
        }
    } else {
        "absent"
    };
    (
        name,
        points.len(),
        temporality != "invalid" && points.iter().all(validator),
        temporality,
        monotonic,
    )
}

fn json_metric_point_attributes(output: &mut String, metric: &Value) {
    let data = metric.get("data").unwrap_or(metric);
    output.push('(');
    for (snake, camel) in [
        ("gauge", "gauge"),
        ("sum", "sum"),
        ("histogram", "histogram"),
        ("exponential_histogram", "exponentialHistogram"),
        ("summary", "summary"),
    ] {
        if let Some(data) = json_non_null_field(data, snake, camel) {
            for point in array(json_field(data, "data_points", "dataPoints")) {
                attributes(output, point.get("attributes"));
            }
        }
    }
    output.push(')');
}

fn json_point_metadata_valid(point: &Value) -> bool {
    let Ok(start) = try_integer(json_field(
        point,
        "start_time_unix_nano",
        "startTimeUnixNano",
    )) else {
        return false;
    };
    let Ok(time) = try_integer(json_field(point, "time_unix_nano", "timeUnixNano")) else {
        return false;
    };
    let Ok(flags) = try_integer(point.get("flags")) else {
        return false;
    };
    time > 0
        && start >= 0
        && start <= time
        && matches!(flags, 0 | 1)
        && json_key_values_valid(point.get("attributes"))
}

fn json_no_recorded_value(point: &Value) -> bool {
    try_integer(point.get("flags")).is_ok_and(|flags| flags == 1)
}

fn json_number_point_valid(point: &Value) -> bool {
    // Prost's serde representation keeps a oneof under `value`, while OTLP/JSON
    // places asInt/asDouble directly on the point. Mixed captures can contain
    // both representations, so validate the numeric alternative in either.
    let number = point
        .get("value")
        .filter(|value| !value.is_null())
        .unwrap_or(point);
    let as_double = json_non_null_field(number, "as_double", "asDouble");
    let as_integer = json_non_null_field(number, "as_int", "asInt");
    json_point_metadata_valid(point)
        && json_exemplars_valid(point)
        && (json_no_recorded_value(point)
            || match (as_double, as_integer) {
                (Some(value), None) => json_double(value).is_some(),
                (None, Some(value)) => try_integer(Some(value)).is_ok(),
                _ => false,
            })
}

fn json_histogram_point_valid(point: &Value) -> bool {
    if json_point_metadata_valid(point)
        && json_exemplars_valid(point)
        && json_no_recorded_value(point)
    {
        return true;
    }
    let counts = array(json_field(point, "bucket_counts", "bucketCounts"));
    let bounds = array(json_field(point, "explicit_bounds", "explicitBounds"));
    let Some(bucket_total) = json_integer_sum(counts) else {
        return false;
    };
    let Ok(count) = try_integer(point.get("count")) else {
        return false;
    };
    json_point_metadata_valid(point)
        && json_exemplars_valid(point)
        && count >= 0
        && counts.len() == bounds.len().saturating_add(1)
        && json_bounds_valid(bounds)
        && bucket_total == count
        && optional_json_double_valid(point.get("sum"))
        && json_extrema_valid(point)
}

fn json_bounds_valid(bounds: &[Value]) -> bool {
    let mut previous = None;
    bounds.iter().all(|value| {
        json_double(value).is_some_and(|current| {
            let increasing = current.is_finite() && previous.is_none_or(|value| value < current);
            previous = Some(current);
            increasing
        })
    })
}

fn json_exponential_histogram_point_valid(point: &Value) -> bool {
    if json_point_metadata_valid(point)
        && json_exemplars_valid(point)
        && json_no_recorded_value(point)
    {
        return true;
    }
    let Some(positive) = json_bucket_total(point.get("positive")) else {
        return false;
    };
    let Some(negative) = json_bucket_total(point.get("negative")) else {
        return false;
    };
    let Ok(zero) = try_integer(json_field(point, "zero_count", "zeroCount")) else {
        return false;
    };
    let Ok(count) = try_integer(point.get("count")) else {
        return false;
    };
    let Ok(scale) = try_integer(point.get("scale")) else {
        return false;
    };
    let Some(zero_threshold) = point
        .get("zero_threshold")
        .or_else(|| point.get("zeroThreshold"))
        .map(json_double)
        .unwrap_or(Some(0.0))
    else {
        return false;
    };
    json_point_metadata_valid(point)
        && json_exemplars_valid(point)
        && (-10..=20).contains(&scale)
        && zero_threshold.is_finite()
        && zero_threshold >= 0.0
        && positive >= 0
        && negative >= 0
        && zero >= 0
        && count >= 0
        && positive
            .checked_add(negative)
            .and_then(|total| total.checked_add(zero))
            == Some(count)
        && optional_json_double_valid(point.get("sum"))
        && json_extrema_valid(point)
}

fn json_summary_point_valid(point: &Value) -> bool {
    if json_point_metadata_valid(point) && json_no_recorded_value(point) {
        return true;
    }
    let Ok(count) = try_integer(point.get("count")) else {
        return false;
    };
    let quantiles = array(json_field(point, "quantile_values", "quantileValues"));
    let mut previous = None;
    json_point_metadata_valid(point)
        && count >= 0
        && optional_json_double_valid(point.get("sum"))
        && quantiles.iter().all(|value| {
            let quantile = value.get("quantile").and_then(json_double);
            let valid = quantile.is_some_and(|quantile| {
                (0.0..=1.0).contains(&quantile)
                    && previous.is_none_or(|previous| previous < quantile)
            }) && value.get("value").and_then(json_double).is_some();
            previous = quantile;
            valid
        })
}

fn json_bucket_total(value: Option<&Value>) -> Option<i128> {
    let Some(value) = value else {
        return Some(0);
    };
    json_integer_sum(array(json_field(value, "bucket_counts", "bucketCounts")))
}

fn json_integer_sum(values: &[Value]) -> Option<i128> {
    values.iter().try_fold(0_i128, |total, value| {
        let value = try_integer(Some(value)).ok()?;
        (value >= 0).then_some(())?;
        total.checked_add(value)
    })
}

fn optional_json_double_valid(value: Option<&Value>) -> bool {
    value.is_none_or(|value| value.is_null() || json_double(value).is_some())
}

fn json_extrema_valid(point: &Value) -> bool {
    let decode = |value: Option<&Value>| -> Option<Option<f64>> {
        match value {
            None | Some(Value::Null) => Some(None),
            Some(value) => json_double(value)
                .filter(|value| value.is_finite())
                .map(Some),
        }
    };
    match (decode(point.get("min")), decode(point.get("max"))) {
        (Some(Some(min)), Some(Some(max))) => min <= max,
        (Some(_), Some(_)) => true,
        _ => false,
    }
}

fn json_exemplars_valid(point: &Value) -> bool {
    array(point.get("exemplars")).iter().all(|exemplar| {
        let time = try_integer(json_field(exemplar, "time_unix_nano", "timeUnixNano"));
        let value = exemplar
            .get("value")
            .filter(|value| !value.is_null())
            .unwrap_or(exemplar);
        let as_double = json_non_null_field(value, "as_double", "asDouble");
        let as_integer = json_non_null_field(value, "as_int", "asInt");
        let selected_value_valid = match (as_double, as_integer) {
            (Some(value), None) => json_double(value).is_some(),
            (None, Some(value)) => try_integer(Some(value)).is_ok(),
            _ => false,
        };
        let trace_id = text(json_field(exemplar, "trace_id", "traceId"));
        let span_id = text(json_field(exemplar, "span_id", "spanId"));
        let context_valid = (trace_id.is_empty() && span_id.is_empty())
            || (valid_hex(trace_id, 32) && valid_hex(span_id, 16));
        time.is_ok_and(|time| time > 0)
            && selected_value_valid
            && context_valid
            && json_key_values_valid(json_field(
                exemplar,
                "filtered_attributes",
                "filteredAttributes",
            ))
    })
}

fn valid_hex(value: &str, width: usize) -> bool {
    value.len() == width
        && value.bytes().all(|byte| byte.is_ascii_hexdigit())
        && value.bytes().any(|byte| byte != b'0')
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
        if let Ok(value) = try_integer(Some(value)) {
            write!(output, "(integer {value})").unwrap();
        } else {
            output.push_str("(other)");
        }
    } else if let Some(value) =
        json_field(value, "bool_value", "boolValue").and_then(Value::as_bool)
    {
        output.push_str(if value {
            "(boolean #t)"
        } else {
            "(boolean #f)"
        });
    } else if let Some(value) =
        json_field(value, "double_value", "doubleValue").and_then(json_double)
    {
        output.push_str("(double ");
        string(output, &double_text(value));
        output.push(')');
    } else if let Some(value) = json_field(value, "bytes_value", "bytesValue") {
        if let Some(bytes) = byte_value(value) {
            output.push_str("(bytes (");
            for byte in bytes {
                write!(output, "{byte} ").unwrap();
            }
            output.push_str("))");
        } else {
            output.push_str("(other)");
        }
    } else if let Some(value) = json_field(value, "array_value", "arrayValue") {
        if let Some(values) = value.get("values").and_then(Value::as_array) {
            output.push_str("(array (");
            for item in values {
                any_value(output, Some(item));
                output.push(' ');
            }
            output.push_str("))");
        } else if value.get("values").is_none() {
            output.push_str("(array ())");
        } else {
            output.push_str("(other)");
        }
    } else if let Some(value) = json_field(value, "kvlist_value", "kvlistValue") {
        if let Some(values) = value.get("values").and_then(Value::as_array) {
            output.push_str("(kvlist (");
            for item in values {
                output.push('(');
                string(output, text(item.get("key")));
                output.push(' ');
                any_value(output, item.get("value"));
                output.push(')');
            }
            output.push_str("))");
        } else if value.get("values").is_none() {
            output.push_str("(kvlist ())");
        } else {
            output.push_str("(other)");
        }
    } else {
        output.push_str("(other)");
    }
}

fn double_text(value: f64) -> String {
    if value.is_nan() {
        String::from("NaN")
    } else if value.is_infinite() && value.is_sign_positive() {
        String::from("Infinity")
    } else if value.is_infinite() {
        String::from("-Infinity")
    } else {
        format!("{value}")
    }
}

fn json_double(value: &Value) -> Option<f64> {
    value.as_f64().or_else(|| match value.as_str()? {
        "NaN" => Some(f64::NAN),
        "Infinity" => Some(f64::INFINITY),
        "-Infinity" => Some(f64::NEG_INFINITY),
        value => value.parse::<f64>().ok().filter(|value| value.is_finite()),
    })
}

fn json_key_values_valid(value: Option<&Value>) -> bool {
    let Some(values) = value else {
        return true;
    };
    if values.is_null() {
        return true;
    }
    let Some(values) = values.as_array() else {
        return false;
    };
    values.iter().enumerate().all(|(index, item)| {
        let Some(key) = item.get("key").and_then(Value::as_str) else {
            return false;
        };
        !key.is_empty()
            && json_any_value_valid(item.get("value"))
            && !values[..index]
                .iter()
                .any(|previous| previous.get("key").and_then(Value::as_str) == Some(key))
    })
}

fn json_any_value_valid(value: Option<&Value>) -> bool {
    let Some(value) = value.map(|value| value.get("value").unwrap_or(value)) else {
        return false;
    };
    let variants = [
        json_field(value, "string_value", "stringValue"),
        json_field(value, "int_value", "intValue"),
        json_field(value, "bool_value", "boolValue"),
        json_field(value, "double_value", "doubleValue"),
        json_field(value, "bytes_value", "bytesValue"),
        json_field(value, "array_value", "arrayValue"),
        json_field(value, "kvlist_value", "kvlistValue"),
    ];
    if variants.iter().filter(|variant| variant.is_some()).count() != 1 {
        return false;
    }
    if let Some(value) = variants[0] {
        value.is_string()
    } else if let Some(value) = variants[1] {
        try_integer(Some(value)).is_ok()
    } else if let Some(value) = variants[2] {
        value.is_boolean()
    } else if let Some(value) = variants[3] {
        json_double(value).is_some()
    } else if let Some(value) = variants[4] {
        byte_value(value).is_some()
    } else if let Some(value) = variants[5] {
        value.get("values").is_none_or(|values| {
            values
                .as_array()
                .is_some_and(|items| items.iter().all(|item| json_any_value_valid(Some(item))))
        })
    } else if let Some(value) = variants[6] {
        json_key_values_valid(value.get("values"))
    } else {
        false
    }
}

fn byte_value(value: &Value) -> Option<Vec<u8>> {
    if let Some(encoded) = value.as_str() {
        return decode_base64(encoded);
    }
    value
        .as_array()?
        .iter()
        .map(|byte| u8::try_from(byte.as_u64()?).ok())
        .collect()
}

fn decode_base64(encoded: &str) -> Option<Vec<u8>> {
    otlp_json::decode_base64(encoded)
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

fn integer(value: Option<&Value>) -> i128 {
    try_integer(value).unwrap_or(-1)
}

fn try_integer(value: Option<&Value>) -> Result<i128, ()> {
    let Some(value) = value else {
        return Ok(0);
    };
    if value.is_null() {
        return Ok(0);
    }
    value
        .as_i64()
        .map(i128::from)
        .or_else(|| value.as_u64().map(i128::from))
        .or_else(|| value.as_str().and_then(|value| value.parse().ok()))
        .ok_or(())
}

fn json_field<'a>(value: &'a Value, snake: &str, camel: &str) -> Option<&'a Value> {
    value.get(snake).or_else(|| value.get(camel))
}

fn json_non_null_field<'a>(value: &'a Value, snake: &str, camel: &str) -> Option<&'a Value> {
    json_field(value, snake, camel).filter(|value| !value.is_null())
}

fn has_duplicate_json_field_spellings(value: &Value) -> bool {
    match value {
        Value::Array(values) => values.iter().any(has_duplicate_json_field_spellings),
        Value::Object(fields) => fields.iter().any(|(name, value)| {
            let duplicate = if name.contains('_') {
                let camel = lower_camel_case(name);
                camel != *name && fields.contains_key(camel.as_str())
            } else {
                false
            };
            duplicate || has_duplicate_json_field_spellings(value)
        }),
        _ => false,
    }
}

fn has_malformed_json_collection(value: &Value) -> bool {
    match value {
        Value::Array(values) => values.iter().any(has_malformed_json_collection),
        Value::Object(fields) => fields.iter().any(|(name, value)| {
            (is_json_collection_field(name) && !value.is_null() && !value.is_array())
                || has_malformed_json_collection(value)
        }),
        _ => false,
    }
}

fn has_malformed_json_string(value: &Value) -> bool {
    match value {
        Value::Array(values) => values.iter().any(has_malformed_json_string),
        Value::Object(fields) => fields.iter().any(|(name, value)| {
            (is_json_string_field(name) && !value.is_null() && !value.is_string())
                || has_malformed_json_string(value)
        }),
        _ => false,
    }
}

fn is_json_string_field(name: &str) -> bool {
    matches!(
        name,
        "description"
            | "event_name"
            | "eventName"
            | "key"
            | "message"
            | "name"
            | "parent_span_id"
            | "parentSpanId"
            | "schema_url"
            | "schemaUrl"
            | "severity_text"
            | "severityText"
            | "span_id"
            | "spanId"
            | "string_value"
            | "stringValue"
            | "trace_id"
            | "traceId"
            | "trace_state"
            | "traceState"
            | "unit"
            | "version"
    )
}

fn is_json_collection_field(name: &str) -> bool {
    matches!(
        name,
        "attributes"
            | "bucket_counts"
            | "bucketCounts"
            | "data_points"
            | "dataPoints"
            | "entity_refs"
            | "entityRefs"
            | "events"
            | "exemplars"
            | "explicit_bounds"
            | "explicitBounds"
            | "filtered_attributes"
            | "filteredAttributes"
            | "links"
            | "log_records"
            | "logRecords"
            | "metrics"
            | "quantile_values"
            | "quantileValues"
            | "resource_logs"
            | "resourceLogs"
            | "resource_metrics"
            | "resourceMetrics"
            | "resource_spans"
            | "resourceSpans"
            | "scope_logs"
            | "scopeLogs"
            | "scope_metrics"
            | "scopeMetrics"
            | "scope_spans"
            | "scopeSpans"
            | "spans"
            | "values"
    )
}

fn lower_camel_case(snake: &str) -> String {
    let mut output = String::with_capacity(snake.len());
    let mut uppercase = false;
    for character in snake.chars() {
        if character == '_' {
            uppercase = true;
        } else if uppercase {
            output.push(character.to_ascii_uppercase());
            uppercase = false;
        } else {
            output.push(character);
        }
    }
    output
}

fn length(value: Option<&Value>) -> usize {
    array(value).len()
}
