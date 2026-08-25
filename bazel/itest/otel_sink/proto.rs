use alloc::string::String;
use alloc::vec::Vec;
use serde::{Serialize, Serializer};

fn hex<S: Serializer>(bytes: &Vec<u8>, serializer: S) -> Result<S::Ok, S::Error> {
    const DIGITS: &[u8; 16] = b"0123456789abcdef";
    let mut text = String::with_capacity(bytes.len() * 2);
    for byte in bytes {
        text.push(DIGITS[(byte >> 4) as usize] as char);
        text.push(DIGITS[(byte & 0xf) as usize] as char);
    }
    serializer.serialize_str(&text)
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct AnyValue {
    #[prost(oneof = "any_value::Value", tags = "1, 2, 3, 4, 5, 6, 7")]
    pub value: Option<any_value::Value>,
}

pub mod any_value {
    use super::{ArrayValue, KeyValueList};
    use alloc::string::String;
    use alloc::vec::Vec;
    use serde::Serialize;

    #[derive(Clone, PartialEq, prost::Oneof, Serialize)]
    #[serde(rename_all = "snake_case")]
    pub enum Value {
        #[prost(string, tag = "1")]
        StringValue(String),
        #[prost(bool, tag = "2")]
        BoolValue(bool),
        #[prost(int64, tag = "3")]
        IntValue(i64),
        #[prost(double, tag = "4")]
        DoubleValue(f64),
        #[prost(message, tag = "5")]
        ArrayValue(ArrayValue),
        #[prost(message, tag = "6")]
        KvlistValue(KeyValueList),
        #[prost(bytes, tag = "7")]
        BytesValue(Vec<u8>),
    }
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct ArrayValue {
    #[prost(message, repeated, tag = "1")]
    pub values: Vec<AnyValue>,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct KeyValueList {
    #[prost(message, repeated, tag = "1")]
    pub values: Vec<KeyValue>,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct KeyValue {
    #[prost(string, tag = "1")]
    pub key: String,
    #[prost(message, optional, tag = "2")]
    pub value: Option<AnyValue>,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct InstrumentationScope {
    #[prost(string, tag = "1")]
    pub name: String,
    #[prost(string, tag = "2")]
    pub version: String,
    #[prost(message, repeated, tag = "3")]
    pub attributes: Vec<KeyValue>,
    #[prost(uint32, tag = "4")]
    pub dropped_attributes_count: u32,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct EntityRef {
    #[prost(string, tag = "1")]
    pub schema_url: String,
    #[prost(string, tag = "2")]
    pub r#type: String,
    #[prost(string, repeated, tag = "3")]
    pub id_keys: Vec<String>,
    #[prost(string, repeated, tag = "4")]
    pub description_keys: Vec<String>,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct Resource {
    #[prost(message, repeated, tag = "1")]
    pub attributes: Vec<KeyValue>,
    #[prost(uint32, tag = "2")]
    pub dropped_attributes_count: u32,
    #[prost(message, repeated, tag = "3")]
    pub entity_refs: Vec<EntityRef>,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct ExportTraceServiceRequest {
    #[prost(message, repeated, tag = "1")]
    pub resource_spans: Vec<ResourceSpans>,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct ResourceSpans {
    #[prost(message, optional, tag = "1")]
    pub resource: Option<Resource>,
    #[prost(message, repeated, tag = "2")]
    pub scope_spans: Vec<ScopeSpans>,
    #[prost(string, tag = "3")]
    pub schema_url: String,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct ScopeSpans {
    #[prost(message, optional, tag = "1")]
    pub scope: Option<InstrumentationScope>,
    #[prost(message, repeated, tag = "2")]
    pub spans: Vec<Span>,
    #[prost(string, tag = "3")]
    pub schema_url: String,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct Span {
    #[prost(bytes, tag = "1")]
    #[serde(serialize_with = "hex")]
    pub trace_id: Vec<u8>,
    #[prost(bytes, tag = "2")]
    #[serde(serialize_with = "hex")]
    pub span_id: Vec<u8>,
    #[prost(string, tag = "3")]
    pub trace_state: String,
    #[prost(bytes, tag = "4")]
    #[serde(serialize_with = "hex")]
    pub parent_span_id: Vec<u8>,
    #[prost(string, tag = "5")]
    pub name: String,
    #[prost(enumeration = "SpanKind", tag = "6")]
    pub kind: i32,
    #[prost(fixed64, tag = "7")]
    pub start_time_unix_nano: u64,
    #[prost(fixed64, tag = "8")]
    pub end_time_unix_nano: u64,
    #[prost(message, repeated, tag = "9")]
    pub attributes: Vec<KeyValue>,
    #[prost(uint32, tag = "10")]
    pub dropped_attributes_count: u32,
    #[prost(message, repeated, tag = "11")]
    pub events: Vec<span::Event>,
    #[prost(uint32, tag = "12")]
    pub dropped_events_count: u32,
    #[prost(message, repeated, tag = "13")]
    pub links: Vec<span::Link>,
    #[prost(uint32, tag = "14")]
    pub dropped_links_count: u32,
    #[prost(message, optional, tag = "15")]
    pub status: Option<Status>,
    #[prost(fixed32, tag = "16")]
    pub flags: u32,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, prost::Enumeration, Serialize)]
#[repr(i32)]
pub enum SpanKind {
    Unspecified = 0,
    Internal = 1,
    Server = 2,
    Client = 3,
    Producer = 4,
    Consumer = 5,
}

pub mod span {
    use super::{hex, KeyValue};
    use alloc::string::String;
    use alloc::vec::Vec;
    use serde::Serialize;

    #[derive(Clone, PartialEq, prost::Message, Serialize)]
    pub struct Event {
        #[prost(fixed64, tag = "1")]
        pub time_unix_nano: u64,
        #[prost(string, tag = "2")]
        pub name: String,
        #[prost(message, repeated, tag = "3")]
        pub attributes: Vec<KeyValue>,
        #[prost(uint32, tag = "4")]
        pub dropped_attributes_count: u32,
    }

    #[derive(Clone, PartialEq, prost::Message, Serialize)]
    pub struct Link {
        #[prost(bytes, tag = "1")]
        #[serde(serialize_with = "hex")]
        pub trace_id: Vec<u8>,
        #[prost(bytes, tag = "2")]
        #[serde(serialize_with = "hex")]
        pub span_id: Vec<u8>,
        #[prost(string, tag = "3")]
        pub trace_state: String,
        #[prost(message, repeated, tag = "4")]
        pub attributes: Vec<KeyValue>,
        #[prost(uint32, tag = "5")]
        pub dropped_attributes_count: u32,
        #[prost(fixed32, tag = "6")]
        pub flags: u32,
    }
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct Status {
    #[prost(string, tag = "2")]
    pub message: String,
    #[prost(enumeration = "StatusCode", tag = "3")]
    pub code: i32,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, prost::Enumeration, Serialize)]
#[repr(i32)]
pub enum StatusCode {
    Unset = 0,
    Ok = 1,
    Error = 2,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct ExportMetricsServiceRequest {
    #[prost(message, repeated, tag = "1")]
    pub resource_metrics: Vec<ResourceMetrics>,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct ResourceMetrics {
    #[prost(message, optional, tag = "1")]
    pub resource: Option<Resource>,
    #[prost(message, repeated, tag = "2")]
    pub scope_metrics: Vec<ScopeMetrics>,
    #[prost(string, tag = "3")]
    pub schema_url: String,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct ScopeMetrics {
    #[prost(message, optional, tag = "1")]
    pub scope: Option<InstrumentationScope>,
    #[prost(message, repeated, tag = "2")]
    pub metrics: Vec<Metric>,
    #[prost(string, tag = "3")]
    pub schema_url: String,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct Metric {
    #[prost(string, tag = "1")]
    pub name: String,
    #[prost(string, tag = "2")]
    pub description: String,
    #[prost(string, tag = "3")]
    pub unit: String,
    #[prost(oneof = "metric::Data", tags = "5, 7, 9, 10, 11")]
    pub data: Option<metric::Data>,
    #[prost(message, repeated, tag = "12")]
    pub metadata: Vec<KeyValue>,
}

pub mod metric {
    use super::{ExponentialHistogram, Gauge, Histogram, Sum, Summary};
    use serde::Serialize;

    #[derive(Clone, PartialEq, prost::Oneof, Serialize)]
    #[serde(rename_all = "snake_case")]
    pub enum Data {
        #[prost(message, tag = "5")]
        Gauge(Gauge),
        #[prost(message, tag = "7")]
        Sum(Sum),
        #[prost(message, tag = "9")]
        Histogram(Histogram),
        #[prost(message, tag = "10")]
        ExponentialHistogram(ExponentialHistogram),
        #[prost(message, tag = "11")]
        Summary(Summary),
    }
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct Gauge {
    #[prost(message, repeated, tag = "1")]
    pub data_points: Vec<NumberDataPoint>,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct Sum {
    #[prost(message, repeated, tag = "1")]
    pub data_points: Vec<NumberDataPoint>,
    #[prost(enumeration = "AggregationTemporality", tag = "2")]
    pub aggregation_temporality: i32,
    #[prost(bool, tag = "3")]
    pub is_monotonic: bool,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct Histogram {
    #[prost(message, repeated, tag = "1")]
    pub data_points: Vec<HistogramDataPoint>,
    #[prost(enumeration = "AggregationTemporality", tag = "2")]
    pub aggregation_temporality: i32,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct ExponentialHistogram {
    #[prost(message, repeated, tag = "1")]
    pub data_points: Vec<ExponentialHistogramDataPoint>,
    #[prost(enumeration = "AggregationTemporality", tag = "2")]
    pub aggregation_temporality: i32,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct Summary {
    #[prost(message, repeated, tag = "1")]
    pub data_points: Vec<SummaryDataPoint>,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, prost::Enumeration, Serialize)]
#[repr(i32)]
pub enum AggregationTemporality {
    Unspecified = 0,
    Delta = 1,
    Cumulative = 2,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct NumberDataPoint {
    #[prost(message, repeated, tag = "7")]
    pub attributes: Vec<KeyValue>,
    #[prost(fixed64, tag = "2")]
    pub start_time_unix_nano: u64,
    #[prost(fixed64, tag = "3")]
    pub time_unix_nano: u64,
    #[prost(oneof = "number_data_point::Value", tags = "4, 6")]
    pub value: Option<number_data_point::Value>,
    #[prost(message, repeated, tag = "5")]
    pub exemplars: Vec<Exemplar>,
    #[prost(uint32, tag = "8")]
    pub flags: u32,
}

pub mod number_data_point {
    use serde::Serialize;

    #[derive(Clone, Copy, PartialEq, prost::Oneof, Serialize)]
    #[serde(rename_all = "snake_case")]
    pub enum Value {
        #[prost(double, tag = "4")]
        AsDouble(f64),
        #[prost(sfixed64, tag = "6")]
        AsInt(i64),
    }
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct HistogramDataPoint {
    #[prost(message, repeated, tag = "9")]
    pub attributes: Vec<KeyValue>,
    #[prost(fixed64, tag = "2")]
    pub start_time_unix_nano: u64,
    #[prost(fixed64, tag = "3")]
    pub time_unix_nano: u64,
    #[prost(fixed64, tag = "4")]
    pub count: u64,
    #[prost(double, optional, tag = "5")]
    pub sum: Option<f64>,
    #[prost(fixed64, repeated, tag = "6")]
    pub bucket_counts: Vec<u64>,
    #[prost(double, repeated, tag = "7")]
    pub explicit_bounds: Vec<f64>,
    #[prost(message, repeated, tag = "8")]
    pub exemplars: Vec<Exemplar>,
    #[prost(uint32, tag = "10")]
    pub flags: u32,
    #[prost(double, optional, tag = "11")]
    pub min: Option<f64>,
    #[prost(double, optional, tag = "12")]
    pub max: Option<f64>,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct ExponentialHistogramDataPoint {
    #[prost(message, repeated, tag = "1")]
    pub attributes: Vec<KeyValue>,
    #[prost(fixed64, tag = "2")]
    pub start_time_unix_nano: u64,
    #[prost(fixed64, tag = "3")]
    pub time_unix_nano: u64,
    #[prost(fixed64, tag = "4")]
    pub count: u64,
    #[prost(double, optional, tag = "5")]
    pub sum: Option<f64>,
    #[prost(sint32, tag = "6")]
    pub scale: i32,
    #[prost(fixed64, tag = "7")]
    pub zero_count: u64,
    #[prost(message, optional, tag = "8")]
    pub positive: Option<Buckets>,
    #[prost(message, optional, tag = "9")]
    pub negative: Option<Buckets>,
    #[prost(uint32, tag = "10")]
    pub flags: u32,
    #[prost(message, repeated, tag = "11")]
    pub exemplars: Vec<Exemplar>,
    #[prost(double, optional, tag = "12")]
    pub min: Option<f64>,
    #[prost(double, optional, tag = "13")]
    pub max: Option<f64>,
    #[prost(double, tag = "14")]
    pub zero_threshold: f64,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct Buckets {
    #[prost(sint32, tag = "1")]
    pub offset: i32,
    #[prost(uint64, repeated, tag = "2")]
    pub bucket_counts: Vec<u64>,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct SummaryDataPoint {
    #[prost(message, repeated, tag = "7")]
    pub attributes: Vec<KeyValue>,
    #[prost(fixed64, tag = "2")]
    pub start_time_unix_nano: u64,
    #[prost(fixed64, tag = "3")]
    pub time_unix_nano: u64,
    #[prost(fixed64, tag = "4")]
    pub count: u64,
    #[prost(double, tag = "5")]
    pub sum: f64,
    #[prost(message, repeated, tag = "6")]
    pub quantile_values: Vec<ValueAtQuantile>,
    #[prost(uint32, tag = "8")]
    pub flags: u32,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct ValueAtQuantile {
    #[prost(double, tag = "1")]
    pub quantile: f64,
    #[prost(double, tag = "2")]
    pub value: f64,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct Exemplar {
    #[prost(message, repeated, tag = "7")]
    pub filtered_attributes: Vec<KeyValue>,
    #[prost(fixed64, tag = "2")]
    pub time_unix_nano: u64,
    #[prost(oneof = "exemplar::Value", tags = "3, 6")]
    pub value: Option<exemplar::Value>,
    #[prost(bytes, tag = "4")]
    #[serde(serialize_with = "hex")]
    pub span_id: Vec<u8>,
    #[prost(bytes, tag = "5")]
    #[serde(serialize_with = "hex")]
    pub trace_id: Vec<u8>,
}

pub mod exemplar {
    use serde::Serialize;

    #[derive(Clone, Copy, PartialEq, prost::Oneof, Serialize)]
    #[serde(rename_all = "snake_case")]
    pub enum Value {
        #[prost(double, tag = "3")]
        AsDouble(f64),
        #[prost(sfixed64, tag = "6")]
        AsInt(i64),
    }
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct ExportLogsServiceRequest {
    #[prost(message, repeated, tag = "1")]
    pub resource_logs: Vec<ResourceLogs>,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct ResourceLogs {
    #[prost(message, optional, tag = "1")]
    pub resource: Option<Resource>,
    #[prost(message, repeated, tag = "2")]
    pub scope_logs: Vec<ScopeLogs>,
    #[prost(string, tag = "3")]
    pub schema_url: String,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct ScopeLogs {
    #[prost(message, optional, tag = "1")]
    pub scope: Option<InstrumentationScope>,
    #[prost(message, repeated, tag = "2")]
    pub log_records: Vec<LogRecord>,
    #[prost(string, tag = "3")]
    pub schema_url: String,
}

#[derive(Clone, PartialEq, prost::Message, Serialize)]
pub struct LogRecord {
    #[prost(fixed64, tag = "1")]
    pub time_unix_nano: u64,
    #[prost(enumeration = "SeverityNumber", tag = "2")]
    pub severity_number: i32,
    #[prost(string, tag = "3")]
    pub severity_text: String,
    #[prost(message, optional, tag = "5")]
    pub body: Option<AnyValue>,
    #[prost(message, repeated, tag = "6")]
    pub attributes: Vec<KeyValue>,
    #[prost(uint32, tag = "7")]
    pub dropped_attributes_count: u32,
    #[prost(fixed32, tag = "8")]
    pub flags: u32,
    #[prost(bytes, tag = "9")]
    #[serde(serialize_with = "hex")]
    pub trace_id: Vec<u8>,
    #[prost(bytes, tag = "10")]
    #[serde(serialize_with = "hex")]
    pub span_id: Vec<u8>,
    #[prost(fixed64, tag = "11")]
    pub observed_time_unix_nano: u64,
    #[prost(string, tag = "12")]
    pub event_name: String,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, prost::Enumeration, Serialize)]
#[repr(i32)]
pub enum SeverityNumber {
    Unspecified = 0,
    Trace = 1,
    Trace2 = 2,
    Trace3 = 3,
    Trace4 = 4,
    Debug = 5,
    Debug2 = 6,
    Debug3 = 7,
    Debug4 = 8,
    Info = 9,
    Info2 = 10,
    Info3 = 11,
    Info4 = 12,
    Warn = 13,
    Warn2 = 14,
    Warn3 = 15,
    Warn4 = 16,
    Error = 17,
    Error2 = 18,
    Error3 = 19,
    Error4 = 20,
    Fatal = 21,
    Fatal2 = 22,
    Fatal3 = 23,
    Fatal4 = 24,
}
