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
}

#[derive(Serialize)]
#[serde(untagged)]
pub(crate) enum Payload {
    Traces(proto::ExportTraceServiceRequest),
    Metrics(proto::ExportMetricsServiceRequest),
    Logs(proto::ExportLogsServiceRequest),
    Json(Value),
}
