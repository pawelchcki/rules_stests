use crate::data::{Payload, Record};
use crate::proto;
use alloc::collections::{BTreeMap, BTreeSet};
use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec::Vec;
use core::fmt::Write;
use serde_json::Value;

const MAX_TRACE_DEPTH: usize = 128;

#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct SemanticSpan {
    pub(crate) scope: String,
    pub(crate) kind: String,
    pub(crate) status: String,
    pub(crate) name: String,
    pub(crate) http_status: Option<i128>,
}

#[derive(Clone, Debug)]
struct RawSpan {
    trace_id: String,
    span_id: String,
    parent_span_id: String,
    semantic: SemanticSpan,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct Group<T> {
    pub(crate) count: usize,
    pub(crate) item: T,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct Node {
    pub(crate) span: SemanticSpan,
    pub(crate) children: Vec<Group<Node>>,
    fingerprint: String,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(crate) enum Coverage {
    Complete,
    Partial,
}

impl Coverage {
    pub(crate) fn name(self) -> &'static str {
        match self {
            Self::Complete => "complete",
            Self::Partial => "partial",
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct Trace {
    pub(crate) coverage: Coverage,
    pub(crate) roots: Vec<Group<Node>>,
    fingerprint: String,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct Forest {
    pub(crate) traces: Vec<Group<Trace>>,
}

pub(crate) fn from_records(records: &[Record]) -> Result<Forest, String> {
    let mut spans = Vec::new();
    for record in records {
        match &record.payload {
            Payload::Traces(payload) => collect_typed(payload, &mut spans)?,
            Payload::Json(payload) if record.signal == "traces" => {
                collect_json(payload, &mut spans)?
            }
            _ => {}
        }
    }
    build(spans)
}

fn collect_typed(
    payload: &proto::ExportTraceServiceRequest,
    output: &mut Vec<RawSpan>,
) -> Result<(), String> {
    for resource in &payload.resource_spans {
        for group in &resource.scope_spans {
            let scope = group.scope.as_ref().map_or("", |scope| scope.name.as_str());
            for span in &group.spans {
                let trace_id = hex(&span.trace_id);
                let span_id = hex(&span.span_id);
                let parent_span_id = hex(&span.parent_span_id);
                validate_span_identity(&trace_id, &span_id, &parent_span_id)?;
                validate_span_fields(
                    &span.name,
                    i128::from(span.start_time_unix_nano),
                    i128::from(span.end_time_unix_nano),
                )?;
                output.push(RawSpan {
                    trace_id,
                    span_id,
                    parent_span_id,
                    semantic: SemanticSpan {
                        scope: scope.to_string(),
                        kind: enum_name(
                            i128::from(span.kind),
                            &[
                                "unspecified",
                                "internal",
                                "server",
                                "client",
                                "producer",
                                "consumer",
                            ],
                            "span kind",
                        )?
                        .to_string(),
                        status: enum_name(
                            i128::from(span.status.as_ref().map_or(0, |status| status.code)),
                            &["unset", "ok", "error"],
                            "span status",
                        )?
                        .to_string(),
                        name: span.name.clone(),
                        http_status: typed_http_status(&span.attributes)?,
                    },
                });
            }
        }
    }
    Ok(())
}

fn collect_json(payload: &Value, output: &mut Vec<RawSpan>) -> Result<(), String> {
    for resource in array(field(payload, "resource_spans", "resourceSpans")) {
        for group in array(field(resource, "scope_spans", "scopeSpans")) {
            let scope = group
                .get("scope")
                .and_then(|scope| scope.get("name"))
                .and_then(Value::as_str)
                .unwrap_or("");
            for span in array(group.get("spans")) {
                let kind = enum_or_default(span.get("kind"), "span kind")?;
                let status = enum_or_default(
                    span.get("status").and_then(|status| status.get("code")),
                    "span status",
                )?;
                let trace_id =
                    string(field(span, "trace_id", "traceId"), "trace ID")?.to_ascii_lowercase();
                let span_id =
                    string(field(span, "span_id", "spanId"), "span ID")?.to_ascii_lowercase();
                let parent_span_id = optional_string(
                    field(span, "parent_span_id", "parentSpanId"),
                    "parent span ID",
                )?
                .to_ascii_lowercase();
                let name = string(span.get("name"), "span name")?;
                validate_span_identity(&trace_id, &span_id, &parent_span_id)?;
                validate_span_fields(
                    name,
                    integer(
                        field(span, "start_time_unix_nano", "startTimeUnixNano"),
                        "span start timestamp",
                    )?,
                    integer(
                        field(span, "end_time_unix_nano", "endTimeUnixNano"),
                        "span end timestamp",
                    )?,
                )?;
                output.push(RawSpan {
                    trace_id,
                    span_id,
                    parent_span_id,
                    semantic: SemanticSpan {
                        scope: scope.to_string(),
                        kind: enum_name(
                            kind,
                            &[
                                "unspecified",
                                "internal",
                                "server",
                                "client",
                                "producer",
                                "consumer",
                            ],
                            "span kind",
                        )?
                        .to_string(),
                        status: enum_name(status, &["unset", "ok", "error"], "span status")?
                            .to_string(),
                        name: name.to_string(),
                        http_status: json_http_status(span.get("attributes"))?,
                    },
                });
            }
        }
    }
    Ok(())
}

fn validate_span_identity(
    trace_id: &str,
    span_id: &str,
    parent_span_id: &str,
) -> Result<(), String> {
    if !valid_hex(trace_id, 32) {
        return Err(format!("invalid trace ID {trace_id:?}"));
    }
    if !valid_hex(span_id, 16) {
        return Err(format!("invalid span ID {span_id:?}"));
    }
    if !parent_span_id.is_empty() && !valid_hex(parent_span_id, 16) {
        return Err(format!("invalid parent span ID {parent_span_id:?}"));
    }
    Ok(())
}

fn validate_span_fields(name: &str, start: i128, end: i128) -> Result<(), String> {
    if name.is_empty() {
        return Err("span has no name".into());
    }
    if start <= 0 || end < start {
        return Err("span timestamps are not ordered".into());
    }
    Ok(())
}

fn valid_hex(value: &str, width: usize) -> bool {
    value.len() == width
        && value.bytes().all(|byte| byte.is_ascii_hexdigit())
        && value.bytes().any(|byte| byte != b'0')
}

fn build(spans: Vec<RawSpan>) -> Result<Forest, String> {
    if spans.is_empty() {
        return Ok(Forest { traces: Vec::new() });
    }
    let mut by_trace = BTreeMap::<String, Vec<RawSpan>>::new();
    let mut identities = BTreeSet::new();
    for span in spans {
        if span.trace_id.is_empty() || span.span_id.is_empty() {
            return Err("trace forest contains an empty trace or span ID".into());
        }
        if !identities.insert((span.trace_id.clone(), span.span_id.clone())) {
            return Err(format!(
                "duplicate span ID {:?} in trace {:?}",
                span.span_id, span.trace_id
            ));
        }
        by_trace
            .entry(span.trace_id.clone())
            .or_default()
            .push(span);
    }

    let mut traces = Vec::new();
    for (trace_id, trace_spans) in by_trace {
        let mut index = BTreeMap::<String, RawSpan>::new();
        for span in trace_spans {
            index.insert(span.span_id.clone(), span);
        }
        let explicit_roots = index
            .values()
            .filter(|span| span.parent_span_id.is_empty())
            .count();
        if explicit_roots > 1 {
            return Err(format!("trace {trace_id:?} has multiple explicit roots"));
        }
        for span_id in index.keys() {
            ensure_acyclic(&trace_id, span_id, &index)?;
        }
        let partial = index.values().any(|span| {
            !span.parent_span_id.is_empty() && !index.contains_key(&span.parent_span_id)
        });
        let root_ids = index
            .values()
            .filter(|span| {
                span.parent_span_id.is_empty() || !index.contains_key(&span.parent_span_id)
            })
            .map(|span| span.span_id.clone())
            .collect::<Vec<_>>();
        if root_ids.is_empty() {
            return Err(format!("trace {trace_id:?} has no root or external anchor"));
        }
        let mut roots = Vec::new();
        for root in root_ids {
            roots.push(build_node(&trace_id, &root, &index, 0)?);
        }
        let roots = group_nodes(roots);
        let coverage = if !partial && explicit_roots == 1 {
            Coverage::Complete
        } else {
            Coverage::Partial
        };
        let fingerprint = trace_fingerprint(coverage, &roots);
        traces.push(Trace {
            coverage,
            roots,
            fingerprint,
        });
    }
    traces.sort_by(|left, right| left.fingerprint.cmp(&right.fingerprint));
    Ok(Forest {
        traces: group_traces(traces),
    })
}

fn ensure_acyclic(
    trace_id: &str,
    start: &str,
    index: &BTreeMap<String, RawSpan>,
) -> Result<(), String> {
    let mut seen = BTreeSet::new();
    let mut current = start;
    while let Some(span) = index.get(current) {
        if !seen.insert(current.to_string()) {
            return Err(format!(
                "span parent topology is cyclic in trace {trace_id:?} at span {current:?}"
            ));
        }
        if span.parent_span_id.is_empty() || !index.contains_key(&span.parent_span_id) {
            return Ok(());
        }
        current = &span.parent_span_id;
    }
    Ok(())
}

fn build_node(
    trace_id: &str,
    span_id: &str,
    index: &BTreeMap<String, RawSpan>,
    depth: usize,
) -> Result<Node, String> {
    if depth >= MAX_TRACE_DEPTH {
        return Err(format!(
            "trace {trace_id:?} exceeds the maximum nesting depth of {MAX_TRACE_DEPTH}"
        ));
    }
    let span = index
        .get(span_id)
        .ok_or_else(|| format!("missing span {span_id:?}"))?;
    let mut children = Vec::new();
    for child in index
        .values()
        .filter(|candidate| candidate.parent_span_id == span_id)
    {
        children.push(build_node(trace_id, &child.span_id, index, depth + 1)?);
    }
    let children = group_nodes(children);
    let fingerprint = node_fingerprint(&span.semantic, &children);
    Ok(Node {
        span: span.semantic.clone(),
        children,
        fingerprint,
    })
}

fn group_nodes(mut nodes: Vec<Node>) -> Vec<Group<Node>> {
    nodes.sort_by(|left, right| left.fingerprint.cmp(&right.fingerprint));
    group_by(nodes, |node| node.fingerprint.clone())
}

fn group_traces(traces: Vec<Trace>) -> Vec<Group<Trace>> {
    group_by(traces, |trace| trace.fingerprint.clone())
}

fn group_by<T, F>(values: Vec<T>, key: F) -> Vec<Group<T>>
where
    F: Fn(&T) -> String,
{
    let mut output = Vec::<Group<T>>::new();
    let mut previous = None::<String>;
    for value in values {
        let current = key(&value);
        if previous.as_ref() == Some(&current) {
            output.last_mut().unwrap().count += 1;
        } else {
            previous = Some(current);
            output.push(Group {
                count: 1,
                item: value,
            });
        }
    }
    output
}

fn node_fingerprint(span: &SemanticSpan, children: &[Group<Node>]) -> String {
    let mut value = format!(
        "{:?}\u{1f}{:?}\u{1f}{:?}\u{1f}{:?}\u{1f}{:?}",
        span.scope, span.kind, span.status, span.name, span.http_status
    );
    for child in children {
        write!(value, "\u{1e}{}*{}", child.count, child.item.fingerprint).unwrap();
    }
    value
}

fn trace_fingerprint(coverage: Coverage, roots: &[Group<Node>]) -> String {
    let mut value = coverage.name().to_string();
    for root in roots {
        write!(value, "\u{1e}{}*{}", root.count, root.item.fingerprint).unwrap();
    }
    value
}

fn typed_http_status(attributes: &[proto::KeyValue]) -> Result<Option<i128>, String> {
    let mut result = None;
    for attribute in attributes
        .iter()
        .filter(|attribute| attribute.key == "http.status_code")
    {
        if result.is_some() {
            return Err("duplicate attribute \"http.status_code\"".into());
        }
        let value = attribute
            .value
            .as_ref()
            .and_then(|value| value.value.as_ref());
        match value {
            Some(proto::any_value::Value::IntValue(value)) => result = Some(i128::from(*value)),
            _ => return Err("attribute \"http.status_code\" is not an integer".into()),
        }
    }
    Ok(result)
}

fn json_http_status(attributes: Option<&Value>) -> Result<Option<i128>, String> {
    let mut result = None;
    for attribute in array(attributes).iter().filter(|attribute| {
        attribute.get("key").and_then(Value::as_str) == Some("http.status_code")
    }) {
        if result.is_some() {
            return Err("duplicate attribute \"http.status_code\"".into());
        }
        let value = attribute
            .get("value")
            .map(|value| value.get("value").unwrap_or(value))
            .and_then(|value| field(value, "int_value", "intValue"));
        result = Some(integer(value, "http.status_code attribute")?);
    }
    Ok(result)
}

fn enum_name<'a>(value: i128, names: &'a [&str], label: &str) -> Result<&'a str, String> {
    names
        .get(usize::try_from(value).unwrap_or(usize::MAX))
        .copied()
        .ok_or_else(|| format!("invalid {label} {value}"))
}

fn integer(value: Option<&Value>, label: &str) -> Result<i128, String> {
    let value = value
        .filter(|value| !value.is_null())
        .unwrap_or(&Value::Null);
    value
        .as_i64()
        .map(i128::from)
        .or_else(|| value.as_u64().map(i128::from))
        .or_else(|| value.as_str().and_then(|value| value.parse::<i128>().ok()))
        .ok_or_else(|| format!("invalid {label}"))
}

fn enum_or_default(value: Option<&Value>, label: &str) -> Result<i128, String> {
    match value {
        None | Some(Value::Null) => Ok(0),
        Some(value) => value
            .as_i64()
            .map(i128::from)
            .or_else(|| value.as_u64().map(i128::from))
            .ok_or_else(|| format!("invalid {label}")),
    }
}

fn string<'a>(value: Option<&'a Value>, label: &str) -> Result<&'a str, String> {
    value
        .and_then(Value::as_str)
        .ok_or_else(|| format!("invalid {label}"))
}

fn optional_string<'a>(value: Option<&'a Value>, label: &str) -> Result<&'a str, String> {
    match value {
        None | Some(Value::Null) => Ok(""),
        Some(value) => value.as_str().ok_or_else(|| format!("invalid {label}")),
    }
}

fn field<'a>(value: &'a Value, snake: &str, camel: &str) -> Option<&'a Value> {
    value.get(snake).or_else(|| value.get(camel))
}

fn array(value: Option<&Value>) -> &[Value] {
    value
        .and_then(Value::as_array)
        .map(Vec::as_slice)
        .unwrap_or(&[])
}

fn hex(bytes: &[u8]) -> String {
    let mut value = String::with_capacity(bytes.len() * 2);
    for byte in bytes {
        write!(value, "{byte:02x}").unwrap();
    }
    value
}
