use crate::data::Payload;
use crate::otlp_json;
use crate::proto;
use alloc::format;
use alloc::string::String;
use alloc::vec::Vec;
use prost::Message;
use serde_json::Value;

pub(crate) fn decode(
    signal: &str,
    content_type: &str,
    body: &[u8],
) -> Result<(&'static str, Payload), String> {
    if content_type == "application/json" {
        let value: Value =
            serde_json::from_slice(body).map_err(|error| format!("invalid OTLP JSON: {error}"))?;
        otlp_json::validate_export(signal, &value)?;
        return Ok(("json", Payload::Json(value)));
    }
    if content_type != "application/x-protobuf" && content_type != "application/protobuf" {
        return Err(format!("unsupported content type {content_type:?}"));
    }
    let value = match signal {
        "traces" => Payload::Traces(
            proto::ExportTraceServiceRequest::decode(body)
                .map_err(|error| format!("invalid trace protobuf: {error}"))?,
        ),
        "metrics" => Payload::Metrics(
            proto::ExportMetricsServiceRequest::decode(body)
                .map_err(|error| format!("invalid metrics protobuf: {error}"))?,
        ),
        "logs" => Payload::Logs(
            proto::ExportLogsServiceRequest::decode(body)
                .map_err(|error| format!("invalid logs protobuf: {error}"))?,
        ),
        _ => unreachable!(),
    };
    Ok(("protobuf", value))
}

pub(crate) fn json_trace_span_count(payload: &Value) -> usize {
    payload
        .get("resource_spans")
        .or_else(|| payload.get("resourceSpans"))
        .and_then(Value::as_array)
        .map(|resources| {
            resources
                .iter()
                .filter_map(|resource| {
                    resource
                        .get("scope_spans")
                        .or_else(|| resource.get("scopeSpans"))
                })
                .filter_map(Value::as_array)
                .flatten()
                .filter_map(|scope| scope.get("spans"))
                .filter_map(Value::as_array)
                .map(Vec::len)
                .sum()
        })
        .unwrap_or(0)
}
