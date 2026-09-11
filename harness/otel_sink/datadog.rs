//! Native Datadog intake. The v0.5 dictionary layout follows dd-apm-test-agent's
//! https://github.com/DataDog/dd-apm-test-agent/blob/master/ddapm_test_agent/trace.py;
//! IDs never pass through floating point.
use crate::data::{Payload, Record};
use alloc::{
    collections::BTreeMap,
    format,
    string::{String, ToString},
    vec::Vec,
};
use core::fmt::Write;
use serde_json::{Map, Number, Value};

const MAX_NODES: usize = 65536;
const MAX_DEPTH: usize = 32;
const MAX_BYTES: usize = 1024 * 1024;

struct Decoder<'a> {
    bytes: &'a [u8],
    pos: usize,
    remaining: usize,
    indexed_maps: bool,
}
impl<'a> Decoder<'a> {
    fn take(&mut self, n: usize) -> Result<&'a [u8], String> {
        let end = self
            .pos
            .checked_add(n)
            .ok_or("MessagePack length overflow")?;
        let bytes = self
            .bytes
            .get(self.pos..end)
            .ok_or("truncated MessagePack")?;
        self.pos = end;
        Ok(bytes)
    }
    fn uint(&mut self, n: usize) -> Result<u64, String> {
        Ok(self
            .take(n)?
            .iter()
            .fold(0u64, |v, b| (v << 8) | u64::from(*b)))
    }
    fn text(&mut self, n: usize) -> Result<Value, String> {
        Ok(Value::String(
            core::str::from_utf8(self.take(n)?)
                .map_err(|_| "invalid MessagePack UTF-8")?
                .into(),
        ))
    }
    fn array(&mut self, n: usize, depth: usize) -> Result<Value, String> {
        if n > self.remaining || n > self.bytes.len().saturating_sub(self.pos) {
            return Err("MessagePack array exceeds budget".into());
        }
        let mut values = Vec::with_capacity(n);
        for _ in 0..n {
            values.push(self.value(depth + 1)?);
        }
        Ok(Value::Array(values))
    }
    fn map(&mut self, n: usize, depth: usize) -> Result<Value, String> {
        if n > self.remaining / 2 || n > self.bytes.len().saturating_sub(self.pos) / 2 {
            return Err("MessagePack map exceeds budget".into());
        }
        let mut values = Map::new();
        for _ in 0..n {
            let key = match self.value(depth + 1)? {
                Value::String(s) if !self.indexed_maps => s,
                Value::Number(n) if self.indexed_maps && n.as_u64().is_some() => {
                    format!("\u{0001}index:{n}")
                }
                _ => return Err("unsupported MessagePack map key".into()),
            };
            let value = self.value(depth + 1)?;
            if values.insert(key, value).is_some() {
                return Err("duplicate MessagePack map key".into());
            }
        }
        Ok(Value::Object(values))
    }
    fn value(&mut self, depth: usize) -> Result<Value, String> {
        if depth > MAX_DEPTH || self.remaining == 0 {
            return Err("MessagePack nesting/node budget exceeded".into());
        }
        self.remaining -= 1;
        let tag = self.uint(1)? as u8;
        Ok(match tag {
            0x00..=0x7f => Value::from(tag),
            0xe0..=0xff => Value::from(tag as i8),
            0xc0 => Value::Null,
            0xc2 => Value::Bool(false),
            0xc3 => Value::Bool(true),
            0xcc..=0xcf => {
                let n = 1usize << (tag - 0xcc);
                Value::from(self.uint(n)?)
            }
            0xd0..=0xd3 => {
                let n = 1usize << (tag - 0xd0);
                let v = self.uint(n)?;
                let shift = (8 - n) * 8;
                Value::from(((v << shift) as i64) >> shift)
            }
            0xca | 0xcb => {
                let f = if tag == 0xca {
                    f32::from_bits(self.uint(4)? as u32) as f64
                } else {
                    f64::from_bits(self.uint(8)?)
                };
                Value::Number(Number::from_f64(f).ok_or("non-finite MessagePack number")?)
            }
            0xa0..=0xbf => self.text((tag & 31) as usize)?,
            0xd9..=0xdb => {
                let n = self.uint(1usize << (tag - 0xd9))? as usize;
                self.text(n)?
            }
            0x90..=0x9f => self.array((tag & 15) as usize, depth)?,
            0xdc | 0xdd => {
                let n = self.uint(if tag == 0xdc { 2 } else { 4 })? as usize;
                self.array(n, depth)?
            }
            0x80..=0x8f => self.map((tag & 15) as usize, depth)?,
            0xde | 0xdf => {
                let n = self.uint(if tag == 0xde { 2 } else { 4 })? as usize;
                self.map(n, depth)?
            }
            0xc4..=0xc6 => {
                let n = self.uint(1usize << (tag - 0xc4))? as usize;
                if n > self.remaining {
                    return Err("MessagePack binary exceeds budget".into());
                }
                self.remaining -= n;
                Value::Array(self.take(n)?.iter().map(|b| Value::from(*b)).collect())
            }
            _ => return Err(format!("unsupported MessagePack tag {tag:#x}")),
        })
    }
}

pub(crate) fn decode(path: &str, content_type: &str, bytes: &[u8]) -> Result<Payload, String> {
    if bytes.len() > MAX_BYTES {
        return Err("Datadog payload exceeds limit".into());
    }
    let value = if content_type == "application/json" {
        if path != "/v0.4/traces" {
            return Err("v0.5 requires MessagePack".into());
        }
        {
            use serde::de::DeserializeSeed;
            let mut decoder = serde_json::Deserializer::from_slice(bytes);
            let mut remaining = MAX_NODES;
            let value = JsonSeed {
                remaining: &mut remaining,
                depth: 0,
            }
            .deserialize(&mut decoder)
            .map_err(|e| format!("Datadog JSON: {e}"))?;
            decoder.end().map_err(|e| format!("Datadog JSON: {e}"))?;
            value
        }
    } else {
        let mut decoder = Decoder {
            bytes,
            pos: 0,
            remaining: MAX_NODES,
            indexed_maps: path == "/v0.5/traces",
        };
        let value = decoder.value(0)?;
        if decoder.pos != bytes.len() {
            return Err("trailing MessagePack bytes".into());
        }
        value
    };
    let traces = if path == "/v0.5/traces" {
        decode_v05(value)?
    } else {
        value
    };
    // Structural violations with a decodable native representation are retained.
    Ok(Payload::Json(
        serde_json::json!({"wire_version": if path == "/v0.5/traces" {"v0.5"} else {"v0.4"}, "traces": traces}),
    ))
}
fn lookup(dictionary: &[Value], value: &Value, remaining: &mut usize) -> Result<Value, String> {
    let index = value
        .as_u64()
        .and_then(|n| usize::try_from(n).ok())
        .ok_or("invalid v0.5 dictionary index")?;
    let value = dictionary
        .get(index)
        .ok_or("v0.5 dictionary index out of bounds")?;
    let cost = value.as_str().map_or(0, str::len) + core::mem::size_of::<Value>();
    *remaining = remaining
        .checked_sub(cost)
        .ok_or("v0.5 expanded dictionary exceeds budget")?;
    Ok(value.clone())
}

fn decode_v05(value: Value) -> Result<Value, String> {
    let mut remaining = MAX_BYTES;
    let pair = value
        .as_array()
        .filter(|a| a.len() == 2)
        .ok_or("v0.5 expected [dictionary,traces]")?;
    let dictionary = pair[0]
        .as_array()
        .ok_or("v0.5 dictionary is not an array")?;
    if dictionary.iter().any(|v| !v.is_string()) {
        return Err("v0.5 dictionary entries must be strings".into());
    }
    let traces = pair[1].as_array().ok_or("v0.5 traces is not an array")?;
    let mut decoded = Vec::new();
    for trace in traces {
        let mut spans = Vec::new();
        for span in trace.as_array().ok_or("v0.5 chunk is not an array")? {
            let fields = span
                .as_array()
                .filter(|s| s.len() == 12)
                .ok_or("v0.5 span requires twelve fields")?;
            let names = [
                "service",
                "name",
                "resource",
                "trace_id",
                "span_id",
                "parent_id",
                "start",
                "duration",
                "error",
                "meta",
                "metrics",
                "type",
            ];
            let mut native = Map::new();
            for (index, name) in names.iter().enumerate() {
                let field = &fields[index];
                let value = match index {
                    0..=2 | 11 => lookup(dictionary, field, &mut remaining)?,
                    9 | 10 => {
                        let mut entries = Map::new();
                        for (key, value) in
                            field.as_object().ok_or("v0.5 meta/metrics must be maps")?
                        {
                            let index = key
                                .strip_prefix('\u{0001}')
                                .and_then(|s| s.strip_prefix("index:"))
                                .and_then(|s| s.parse::<u64>().ok())
                                .ok_or("v0.5 map keys must be dictionary indexes")?;
                            let key = lookup(dictionary, &Value::from(index), &mut remaining)?
                                .as_str()
                                .unwrap()
                                .to_string();
                            let value = if *name == "meta" {
                                lookup(dictionary, value, &mut remaining)?
                            } else {
                                value.clone()
                            };
                            if entries.insert(key, value).is_some() {
                                return Err("duplicate decoded v0.5 dictionary key".into());
                            }
                        }
                        Value::Object(entries)
                    }
                    _ => field.clone(),
                };
                native.insert((*name).into(), value);
            }
            spans.push(Value::Object(native));
        }
        decoded.push(Value::Array(spans));
    }
    Ok(Value::Array(decoded))
}

pub(crate) fn payload(record: &Record) -> &Value {
    match &record.payload {
        Payload::Json(v) => v,
        _ => unreachable!(),
    }
}
pub(crate) fn array(v: Option<&Value>) -> &[Value] {
    v.and_then(Value::as_array)
        .map(Vec::as_slice)
        .unwrap_or(&[])
}
fn text(v: Option<&Value>) -> &str {
    v.and_then(Value::as_str).unwrap_or("")
}
fn uint(v: Option<&Value>) -> Option<u64> {
    v.and_then(Value::as_u64)
}
// v0.4 omits a zero parent ID. Absence is a protocol default; explicit
// nulls and wrongly typed values remain semantic violations in the raw capture.
fn parent_id(span: &Value) -> Option<u64> {
    match span.get("parent_id") {
        None => Some(0),
        Some(value) => value.as_u64(),
    }
}
fn integer(v: Option<&Value>) -> String {
    v.filter(|v| v.as_u64().is_some() || v.as_i64().is_some())
        .map(ToString::to_string)
        .unwrap_or_default()
}
fn valid_span(span: &Value) -> bool {
    span.is_object()
        && span.as_object().is_some_and(|object| object.keys().all(|key| matches!(key.as_str(),
            "service" | "name" | "resource" | "trace_id" | "span_id" | "parent_id" |
            "start" | "duration" | "error" | "meta" | "metrics" | "type")))
        && ["trace_id", "span_id"]
            .iter()
            .all(|key| uint(span.get(*key)).is_some_and(|id| id > 0))
        && parent_id(span).is_some()
        && ["name", "service", "resource"]
            .iter()
            .all(|key| !text(span.get(*key)).is_empty())
        && span.get("type").is_none_or(Value::is_string)
        && uint(span.get("start")).is_some_and(|v| v > 0)
        && uint(span.get("duration")).is_some_and(|v| v > 0)
        && span
            .get("error")
            .is_none_or(|v| matches!(v.as_u64(), Some(0 | 1)))
        && span.get("meta").is_none_or(|v| {
            v.as_object()
                .is_some_and(|m| m.values().all(Value::is_string))
        })
        && span.get("metrics").is_none_or(|v| {
            v.as_object()
                .is_some_and(|m| m.values().all(Value::is_number))
        })
        && span
            .get("meta")
            .and_then(|v| v.get("_dd.p.tid"))
            .is_none_or(|v| {
                v.as_str()
                    .is_some_and(|s| s.len() == 16 && s.bytes().all(|b| b.is_ascii_hexdigit()))
            })
}
fn valid_record(record: &Record) -> bool {
    let traces = payload(record).get("traces");
    traces.is_some_and(Value::is_array)
        && array(traces).iter().all(|trace| {
            trace.as_array().is_some_and(|spans| {
                !spans.is_empty()
                    && spans.iter().all(valid_span)
                    && spans
                        .iter()
                        .all(|span| span.get("trace_id") == spans[0].get("trace_id"))
            })
        })
}
pub(crate) fn span_count(record: &Record) -> usize {
    array(payload(record).get("traces"))
        .iter()
        .map(|t| array(Some(t)).len())
        .sum()
}
fn string(out: &mut String, value: &str) {
    out.push('"');
    for c in value.chars() {
        match c {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if c.is_control() => {
                write!(out, "\\x{:x};", c as u32).unwrap();
            }
            _ => out.push(c),
        }
    }
    out.push('"');
}
fn value_scheme(out: &mut String, v: &Value) {
    match v {
        Value::Null => out.push_str("#f"),
        Value::Bool(b) => out.push_str(if *b { "#t" } else { "#f" }),
        Value::String(s) => string(out, s),
        Value::Number(n) => {
            if n.as_i64()
                .is_some_and(|n| n.unsigned_abs() <= 9_007_199_254_740_991)
                || n.as_f64().is_some() && !n.is_u64() && !n.is_i64()
            {
                out.push_str(&n.to_string());
            } else {
                string(out, &n.to_string());
            }
        }
        Value::Array(a) => {
            out.push('(');
            for v in a {
                value_scheme(out, v);
                out.push(' ');
            }
            out.push(')');
        }
        Value::Object(m) => {
            out.push('(');
            for (k, v) in m {
                out.push('(');
                string(out, k);
                out.push(' ');
                value_scheme(out, v);
                out.push(')');
            }
            out.push(')');
        }
    }
}
fn field(out: &mut String, name: &str, value: &str) {
    write!(out, "({name} ").unwrap();
    string(out, value);
    out.push(')');
}

pub(crate) fn capture_to_scheme(records: &[Record]) -> Result<Vec<u8>, String> {
    let trace_shapes = shapes(records);
    let mut out = String::from("((protocol datadog)(family \"datadog\")");
    write!(
        out,
        "(semantic-valid {})(requests (",
        if trace_shapes.is_ok() { "#t" } else { "#f" }
    )
    .unwrap();
    for record in records {
        out.push('(');
        for (k, v) in [
            ("wire-version", text(payload(record).get("wire_version"))),
            ("method", record.request.method.as_str()),
            ("path", record.request.path.as_str()),
            ("http-version", record.request.http_version.as_str()),
            ("content-type", record.request.content_type.as_str()),
            ("content-encoding", record.request.content_encoding.as_str()),
        ] {
            field(&mut out, k, v);
        }
        field(
            &mut out,
            "received-unix-nano",
            &record.received_unix_nano.to_string(),
        );
        field(&mut out, "remote-address", &record.remote_address);
        field(
            &mut out,
            "trace-count",
            record
                .request
                .headers
                .iter()
                .find(|h| h.name == "x-datadog-trace-count")
                .map(|h| h.value.as_str())
                .unwrap_or(""),
        );
        write!(out,"(content-length {})(decoded-length {})(chunk-count {})(span-count {})(semantic-valid {})(headers (",record.request.content_length,record.request.decoded_length,array(payload(record).get("traces")).len(),span_count(record),if valid_record(record) {"#t"} else {"#f"}).unwrap();
        for h in &record.request.headers {
            out.push('(');
            string(&mut out, &h.name);
            out.push(' ');
            string(&mut out, &h.value);
            out.push(')');
        }
        out.push_str(")))");
    }
    out.push_str("))(chunks (");
    let mut chunk_index = 0;
    for (request_index, record) in records.iter().enumerate() {
        for trace in array(payload(record).get("traces")) {
            write!(
                out,
                "((request-index {request_index})(chunk-index {chunk_index})(span-count {}))",
                array(Some(trace)).len()
            )
            .unwrap();
            chunk_index += 1;
        }
    }
    out.push_str("))(spans (");
    chunk_index = 0;
    for (request_index, record) in records.iter().enumerate() {
        for trace in array(payload(record).get("traces")) {
            let spans = array(Some(trace));
            for span in spans {
                out.push('(');
                for name in ["name", "resource", "service", "type"] {
                    field(&mut out, name, text(span.get(name)));
                }
                for name in ["trace_id", "span_id", "parent_id", "start", "duration"] {
                    let value = if name == "parent_id" {
                        parent_id(span).map(|id| id.to_string()).unwrap_or_default()
                    } else {
                        integer(span.get(name))
                    };
                    field(&mut out, &name.replace('_', "-"), &value);
                }
                field(&mut out, "parent-kind", parent_kind(span, spans.iter()));
                write!(out,"(error {})(request-index {request_index})(chunk-index {chunk_index})(semantic-valid {})(ids-valid {})(completed {})",integer(span.get("error")).parse::<i64>().unwrap_or(0),if valid_span(span){"#t"}else{"#f"},if ["trace_id","span_id"].iter().all(|k|uint(span.get(*k)).is_some_and(|v|v>0))&&parent_id(span).is_some(){"#t"}else{"#f"},if uint(span.get("start")).is_some_and(|v|v>0)&&uint(span.get("duration")).is_some_and(|v|v>0){"#t"}else{"#f"}).unwrap();
                for key in ["meta", "metrics"] {
                    write!(out, "({key} ").unwrap();
                    if let Some(v) = span.get(key) {
                        value_scheme(&mut out, v)
                    } else {
                        out.push_str("()")
                    }
                    out.push(')');
                }
                out.push(')');
            }
            chunk_index += 1;
        }
    }
    let mut http_spans = 0usize;
    let mut database_spans = 0usize;
    let mut exact_fields = 0usize;
    let mut normalized_fields = 0usize;
    let mut runtime_fields = 0usize;
    for record in records {
        for trace in array(payload(record).get("traces")) {
            let spans = array(Some(trace));
            let trace_service = spans
                .iter()
                .find(|span| matches!(text(span.get("name")), "aiohttp.request" | "django.request"))
                .map(|span| text(span.get("service")))
                .unwrap_or("");
            for span in spans {
                let name = text(span.get("name"));
                if matches!(name, "aiohttp.request" | "django.request") { http_spans += 1; }
                if text(span.get("type")) == "sql" || name.starts_with("sqlite.") { database_spans += 1; }
                if let Some(object) = span.as_object() {
                    for key in object.keys() {
                        match key.as_str() {
                            "trace_id" | "span_id" | "parent_id" | "start" | "duration" => runtime_fields += 1,
                            "service" if text(span.get("service")) == trace_service => normalized_fields += 1,
                            "service" => exact_fields += 1,
                            "meta" => {
                                exact_fields += 1; // map presence
                                if let Some(fields) = span.get(key).and_then(Value::as_object) {
                                    for (meta_key, meta_value) in fields {
                                        match meta_key.as_str() {
                                            "runtime-id" | "_dd.p.tid" | "error.stack" => runtime_fields += 1,
                                            _ if normalized_meta_value(meta_key, meta_value, trace_service).is_ok_and(|normalized| normalized != *meta_value) => normalized_fields += 1,
                                            _ => exact_fields += 1,
                                        }
                                    }
                                }
                            }
                            "metrics" => {
                                exact_fields += 1; // map presence
                                if let Some(fields) = span.get(key).and_then(Value::as_object) {
                                    for metric_key in fields.keys() {
                                        if metric_key == "process_id" { runtime_fields += 1; } else { exact_fields += 1; }
                                    }
                                }
                            }
                            _ => exact_fields += 1,
                        }
                    }
                }
            }
        }
    }
    write!(out, "))(coverage ((policy-schema 1)(http-spans {http_spans})(database-spans {database_spans})(exact-fields {exact_fields})(normalized-fields {normalized_fields})(runtime-validated-fields {runtime_fields})(unclassified-fields 0)))(trace-shapes ").unwrap();
    match trace_shapes {
        Ok(s) => out.push_str(&s),
        Err(_) => out.push_str("#f"),
    }
    out.push_str("))\n");
    Ok(out.into_bytes())
}

pub(crate) fn capture_to_scheme_with_context(
    records: &[Record],
    app: &str,
    scenario: &str,
) -> Result<Vec<u8>, String> {
    if !app.is_empty() || !scenario.is_empty() {
        validate_workload_context(records, app, scenario)?;
    }
    capture_to_scheme(records)
}

fn context_identifier(value: &str) -> bool {
    !value.is_empty() && value.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'-' || b == b'_')
}

fn validate_workload_context(records: &[Record], app: &str, scenario: &str) -> Result<(), String> {
    if !context_identifier(app) || !context_identifier(scenario) {
        return Err("invalid Datadog workload context".into());
    }
    let expected = match app {
        "aiohttp" => "aiohttp.request",
        "django" => "django.request",
        _ => return Err("unknown Datadog application context".into()),
    };
    if !records.iter().any(|record| array(payload(record).get("traces")).iter().any(|trace|
        array(Some(trace)).iter().any(|span| text(span.get("name")) == expected)))
    {
        return Err("Datadog capture does not match workload application".into());
    }
    Ok(())
}
fn parent_kind<'a>(span: &Value, mut spans: impl Iterator<Item = &'a Value>) -> &'static str {
    if parent_id(span) == Some(0) {
        "root"
    } else if spans.any(|s| {
        uint(s.get("span_id")) == parent_id(span) && s.get("trace_id") == span.get("trace_id")
    }) {
        "child"
    } else {
        "remote"
    }
}

// Exact native names and resources include stable SQL literals and LIMITs.
// Only the fixture's temporary SQLite database path is normalized below.
fn normalize_endpoint(value: &str) -> String {
    for prefix in ["http://127.0.0.1:", "http://localhost:"] {
        if let Some(rest) = value.strip_prefix(prefix) {
            if let Some(offset) = rest.find('/') {
                let (port, suffix) = rest.split_at(offset);
                if !port.is_empty() && port.bytes().all(|b| b.is_ascii_digit()) {
                    return normalize_workload_id(&format!("http://<endpoint>{suffix}"));
                }
            }
        }
    }
    normalize_workload_id(value)
}

fn normalize_workload_id(value: &str) -> String {
    let underscore = normalize_workload_marker(value, "rules_stests_");
    normalize_workload_marker(&underscore, "rules-stests-")
}

fn normalize_workload_marker(value: &str, marker: &str) -> String {
    let mut remaining = value;
    let mut out = String::new();
    while let Some(offset) = remaining.find(marker) {
        out.push_str(&remaining[..offset]);
        let after = &remaining[offset + marker.len()..];
        let digits = after.bytes().take_while(|b| b.is_ascii_digit()).count();
        if digits == 0 {
            out.push_str(marker);
            remaining = after;
            continue;
        }
        out.push_str(marker);
        out.push_str("<workload>");
        remaining = &after[digits..];
        if remaining.len() >= 9
            && remaining.as_bytes()[0] == b'-'
            && remaining.as_bytes()[1..9].iter().all(|b| b.is_ascii_hexdigit())
        {
            remaining = &remaining[9..];
        }
    }
    out.push_str(remaining);
    out
}

fn normalized_meta_value(key: &str, value: &Value, service: &str) -> Result<Value, String> {
    let text = value.as_str().ok_or("Datadog metadata value is not text")?;
    Ok(Value::String(match key {
        "runtime-id" => {
            let compact = text.len() == 32 && text.bytes().all(|b| b.is_ascii_hexdigit());
            let canonical = text.len() == 36 && text.bytes().enumerate().all(|(index, byte)| {
                if matches!(index, 8 | 13 | 18 | 23) {
                    byte == b'-'
                } else {
                    byte.is_ascii_hexdigit()
                }
            });
            if !compact && !canonical {
                return Err("malformed Datadog runtime-id".into());
            }
            "<runtime-id>".into()
        }
        "_dd.p.tid" => {
            if text.len() != 16 || !text.bytes().all(|b| b.is_ascii_hexdigit()) {
                return Err("malformed Datadog trace high bits".into());
            }
            "<trace-id-high>".into()
        }
        "error.stack" => {
            if text.is_empty() || !text.contains("Traceback") {
                return Err("malformed Datadog exception stack".into());
            }
            "<validated-stack>".into()
        }
        "http.url" => normalize_endpoint(text),
        "db.name" | "sql.db" if text.ends_with("realworld.sqlite3") => "<fixture>/realworld.sqlite3".into(),
        "_dd.base_service" if text == service => "<service>".into(),
        _ => normalize_workload_id(text),
    }))
}

fn normalized_metric_value(key: &str, value: &Value) -> Result<Value, String> {
    if key == "process_id" {
        if !value.as_u64().is_some_and(|v| v >= 1)
            && !value.as_i64().is_some_and(|v| v >= 1)
            && !value.as_f64().is_some_and(|v| {
                v.is_finite() && v >= 1.0 && v <= u64::MAX as f64 && (v as u64) as f64 == v
            })
        {
            return Err("malformed Datadog process_id".into());
        }
        return Ok(Value::String("<process-id>".into()));
    }
    Ok(value.clone())
}

fn validate_exception_consistency(span: &Value) -> Result<(), String> {
    let Some(meta) = span.get("meta").and_then(Value::as_object) else { return Ok(()); };
    let Some(stack) = meta.get("error.stack").and_then(Value::as_str) else { return Ok(()); };
    let exception_type = meta.get("error.type").and_then(Value::as_str).unwrap_or("");
    let short_type = exception_type.rsplit('.').next().unwrap_or(exception_type);
    let message = meta.get("error.message").or_else(|| meta.get("error.msg")).and_then(Value::as_str).unwrap_or("");
    if (short_type.is_empty() || !stack.contains(short_type)) && (message.is_empty() || !stack.contains(message)) {
        return Err("Datadog exception stack is inconsistent with type/message".into());
    }
    Ok(())
}

fn node(
    span: &Value,
    spans: &[&Value],
    trace_service: &str,
    depth: usize,
    visited: &mut usize,
) -> Result<String, String> {
    if depth > 64 || *visited >= spans.len() {
        return Err("Datadog cyclic/deep parent graph".into());
    }
    *visited += 1;
    validate_exception_consistency(span)?;
    let mut out = String::from("(");
    out.push_str("(native-fields (");
    if let Some(object) = span.as_object() {
        for key in object.keys() {
            string(&mut out, key);
            out.push(' ');
        }
    }
    out.push_str("))");
    field(&mut out, "service", if text(span.get("service")) == trace_service { "<service>" } else { text(span.get("service")) });
    for name in ["name", "type"] { field(&mut out, name, text(span.get(name))); }
    field(&mut out, "resource", text(span.get("resource")));
    field(
        &mut out,
        "parent-kind",
        parent_kind(span, spans.iter().copied()),
    );
    if parent_kind(span, spans.iter().copied()) == "remote" {
        field(&mut out, "parent-id", &integer(span.get("parent_id")));
        field(&mut out, "trace-id", &integer(span.get("trace_id")));
        field(
            &mut out,
            "trace-id-high",
            text(span.get("meta").and_then(|m| m.get("_dd.p.tid"))),
        );
    }
    write!(
        out,
        "(error {})(meta (",
        integer(span.get("error")).parse::<i64>().unwrap_or(0)
    )
    .unwrap();
    if let Some(meta) = span.get("meta").and_then(Value::as_object) {
        for (key, value) in meta {
            out.push('(');
            string(&mut out, key);
            out.push(' ');
            value_scheme(&mut out, &normalized_meta_value(key, value, trace_service)?);
            out.push(')');
        }
    }
    out.push_str("))(metrics (");
    if let Some(metrics) = span.get("metrics").and_then(Value::as_object) {
        for (key, value) in metrics {
            out.push('(');
            string(&mut out, key);
            out.push(' ');
            value_scheme(&mut out, &normalized_metric_value(key, value)?);
            out.push(')');
        }
    }
    out.push_str("))(children (");
    let mut children = Vec::new();
    for child in spans
        .iter()
        .filter(|child| parent_id(child) == uint(span.get("span_id")))
    {
        children.push(node(child, spans, trace_service, depth + 1, visited)?);
    }
    children.sort();
    for child in children {
        out.push_str(&child);
    }
    out.push_str(")))");
    Ok(out)
}
fn shapes(records: &[Record]) -> Result<String, String> {
    let mut traces = BTreeMap::<(u64, String), Vec<&Value>>::new();
    for record in records {
        if !valid_record(record) {
            return Err("Datadog semantic payload violation".into());
        }
        for chunk in array(payload(record).get("traces")) {
            let spans = array(Some(chunk));
            let mut high = None::<&str>;
            for span in spans {
                if let Some(tid) = span
                    .get("meta")
                    .and_then(|m| m.get("_dd.p.tid"))
                    .and_then(Value::as_str)
                {
                    if high.is_some_and(|old| !old.eq_ignore_ascii_case(tid)) {
                        return Err("conflicting Datadog trace high bits in chunk".into());
                    }
                    high = Some(tid);
                }
            }
            let high = high.unwrap_or("0000000000000000").to_ascii_lowercase();
            for span in spans {
                traces
                    .entry((uint(span.get("trace_id")).unwrap(), high.clone()))
                    .or_default()
                    .push(span);
            }
        }
    }
    let mut groups = BTreeMap::<String, usize>::new();
    for spans in traces.values() {
        let trace_service = spans
            .iter()
            .find(|span| matches!(text(span.get("name")), "aiohttp.request" | "django.request"))
            .map(|span| text(span.get("service")))
            .ok_or("Datadog trace has no HTTP server span")?;
        let mut ids = BTreeMap::new();
        for span in spans {
            if ids.insert(uint(span.get("span_id")).unwrap(), ()).is_some() {
                return Err("duplicate Datadog span ID".into());
            }
        }
        let mut visited = 0;
        let mut roots = Vec::new();
        for span in spans
            .iter()
            .filter(|s| parent_kind(s, spans.iter().copied()) != "child")
        {
            roots.push(node(span, spans, trace_service, 0, &mut visited)?);
        }
        if visited != spans.len() {
            return Err("Datadog cyclic/disconnected parent graph".into());
        }
        roots.sort();
        // A complete trace has one local root. Multiple remote roots can be
        // legitimate chunks, and their multiplicity remains explicit here.
        let key = format!("({})", roots.join(" "));
        *groups.entry(key).or_default() += 1;
    }
    let mut out = String::from("(");
    for (roots, count) in groups {
        write!(out, "((count {count})(roots {roots}))").unwrap();
    }
    out.push(')');
    Ok(out)
}
pub(crate) fn candidate(records: &[Record], app: &str, scenario: &str) -> Result<Vec<u8>, String> {
    validate_workload_context(records, app, scenario)?;
    if records.iter().all(|r| span_count(r) == 0) {
        return Err("trace capture contains no spans".into());
    }
    Ok(format!(
        "(define scenario-shape\n  '{})\n",
        pretty_shape(&shapes(records)?)
    )
    .into_bytes())
}

// Candidate files are review artifacts; only presentation whitespace differs
// from the canonical datum supplied to Scheme's equal? matcher.
fn pretty_shape(shape: &str) -> String {
    let mut out = String::new();
    let mut depth = 1usize;
    let mut quoted = false;
    let mut escaped = false;
    for c in shape.chars() {
        if quoted {
            out.push(c);
            if escaped {
                escaped = false;
            } else if c == '\\' {
                escaped = true;
            } else if c == '"' {
                quoted = false;
            }
        } else {
            match c {
                '"' => {
                    quoted = true;
                    out.push(c);
                }
                '(' => {
                    if !out.is_empty() {
                        while out.ends_with(' ') {
                            out.pop();
                        }
                        out.push('\n');
                        for _ in 0..depth {
                            out.push_str("  ");
                        }
                    }
                    out.push(c);
                    depth += 1;
                }
                ')' => {
                    depth -= 1;
                    out.push(c);
                }
                _ => out.push(c),
            }
        }
    }
    out
}

// Seeded JSON decoding enforces the same allocation/nesting budgets as
// MessagePack and rejects duplicate keys rather than silently losing evidence.
struct JsonSeed<'a> {
    remaining: &'a mut usize,
    depth: usize,
}
impl<'de> serde::de::DeserializeSeed<'de> for JsonSeed<'_> {
    type Value = Value;
    fn deserialize<D: serde::Deserializer<'de>>(self, deserializer: D) -> Result<Value, D::Error> {
        if self.depth > MAX_DEPTH || *self.remaining == 0 {
            return Err(serde::de::Error::custom(
                "Datadog JSON nesting/node budget exceeded",
            ));
        }
        *self.remaining -= 1;
        deserializer.deserialize_any(self)
    }
}
impl<'de> serde::de::Visitor<'de> for JsonSeed<'_> {
    type Value = Value;
    fn expecting(&self, f: &mut core::fmt::Formatter) -> core::fmt::Result {
        f.write_str("bounded Datadog JSON value")
    }
    fn visit_unit<E: serde::de::Error>(self) -> Result<Value, E> {
        Ok(Value::Null)
    }
    fn visit_bool<E: serde::de::Error>(self, v: bool) -> Result<Value, E> {
        Ok(Value::Bool(v))
    }
    fn visit_i64<E: serde::de::Error>(self, v: i64) -> Result<Value, E> {
        Ok(Value::from(v))
    }
    fn visit_u64<E: serde::de::Error>(self, v: u64) -> Result<Value, E> {
        Ok(Value::from(v))
    }
    fn visit_f64<E: serde::de::Error>(self, v: f64) -> Result<Value, E> {
        Ok(Value::Number(
            Number::from_f64(v).ok_or_else(|| E::custom("non-finite JSON number"))?,
        ))
    }
    fn visit_str<E: serde::de::Error>(self, v: &str) -> Result<Value, E> {
        Ok(Value::String(v.into()))
    }
    fn visit_string<E: serde::de::Error>(self, v: String) -> Result<Value, E> {
        Ok(Value::String(v))
    }
    fn visit_seq<A: serde::de::SeqAccess<'de>>(self, mut seq: A) -> Result<Value, A::Error> {
        let mut values = Vec::new();
        while let Some(value) = seq.next_element_seed(JsonSeed {
            remaining: self.remaining,
            depth: self.depth + 1,
        })? {
            values.push(value);
        }
        Ok(Value::Array(values))
    }
    fn visit_map<A: serde::de::MapAccess<'de>>(self, mut map: A) -> Result<Value, A::Error> {
        let mut values = Map::new();
        while let Some(key) = map.next_key::<String>()? {
            if *self.remaining == 0 {
                return Err(serde::de::Error::custom(
                    "Datadog JSON node budget exceeded",
                ));
            }
            *self.remaining -= 1;
            let value = map.next_value_seed(JsonSeed {
                remaining: self.remaining,
                depth: self.depth + 1,
            })?;
            if values.insert(key, value).is_some() {
                return Err(serde::de::Error::custom("duplicate Datadog JSON key"));
            }
        }
        Ok(Value::Object(values))
    }
}
