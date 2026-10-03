use crate::proto;
use alloc::string::String;
use alloc::vec::Vec;
use serde::Serialize;
use serde_json::Value;

#[derive(Serialize)]
pub(crate) struct Header {
    pub(crate) name: String,
    pub(crate) value: String,
}

#[derive(Serialize)]
pub(crate) struct RequestMetadata {
    pub(crate) method: String,
    pub(crate) path: String,
    pub(crate) http_version: String,
    pub(crate) headers: Vec<Header>,
    pub(crate) content_type: String,
    pub(crate) content_encoding: String,
    pub(crate) content_length: usize,
    pub(crate) decoded_length: usize,
}

#[derive(Serialize)]
pub(crate) struct Record {
    pub(crate) received_unix_nano: u64,
    pub(crate) remote_address: String,
    pub(crate) request: RequestMetadata,
    pub(crate) signal: String,
    pub(crate) encoding: String,
    pub(crate) payload: Payload,
    #[serde(skip)]
    pub(crate) retained_bytes: usize,
}

#[derive(Serialize)]
#[serde(untagged)]
pub(crate) enum Payload {
    Traces(proto::ExportTraceServiceRequest),
    Metrics(proto::ExportMetricsServiceRequest),
    Logs(proto::ExportLogsServiceRequest),
    Json(Value),
    Datadog(DatadogPayload),
}

// Capture JSON keeps byte arrays, while validation retains their native wire
// type. Coordinates refer to the original v0.4 chunk and span, never JSON paths.
#[derive(Default)]
pub(crate) struct DatadogWire {
    pub(crate) binary_fields: Vec<(usize, usize, String)>,
    pub(crate) invalid_binary_spans: Vec<(usize, usize)>,
    pub(crate) invalid_binary_container: bool,
    pub(crate) allocation_bytes: usize,
}

#[derive(Serialize)]
#[serde(transparent)]
pub(crate) struct DatadogPayload {
    pub(crate) value: Value,
    #[serde(skip)]
    pub(crate) wire: DatadogWire,
}

impl Payload {
    pub(crate) fn extra_retained_bytes(&self) -> usize {
        match self {
            Self::Datadog(payload) => payload.wire.allocation_bytes,
            _ => 0,
        }
    }
}
