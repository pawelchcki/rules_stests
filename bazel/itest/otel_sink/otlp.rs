use crate::data::Payload;
use crate::otlp_json;
use crate::proto;
use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec::Vec;
use core::fmt;
use prost::Message;
use serde::de::{self, Deserialize, Deserializer, MapAccess, SeqAccess, Visitor};
use serde_json::{Map, Number, Value};

struct UniqueValue(Value);

impl<'de> Deserialize<'de> for UniqueValue {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        deserializer.deserialize_any(UniqueValueVisitor)
    }
}

struct UniqueValueVisitor;

impl<'de> Visitor<'de> for UniqueValueVisitor {
    type Value = UniqueValue;

    fn expecting(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("a JSON value without duplicate object keys")
    }

    fn visit_bool<E>(self, value: bool) -> Result<Self::Value, E> {
        Ok(UniqueValue(Value::Bool(value)))
    }

    fn visit_i64<E>(self, value: i64) -> Result<Self::Value, E> {
        Ok(UniqueValue(Value::Number(value.into())))
    }

    fn visit_u64<E>(self, value: u64) -> Result<Self::Value, E> {
        Ok(UniqueValue(Value::Number(value.into())))
    }

    fn visit_f64<E>(self, value: f64) -> Result<Self::Value, E>
    where
        E: de::Error,
    {
        Number::from_f64(value)
            .map(Value::Number)
            .map(UniqueValue)
            .ok_or_else(|| E::custom("non-finite JSON number"))
    }

    fn visit_str<E>(self, value: &str) -> Result<Self::Value, E> {
        Ok(UniqueValue(Value::String(value.to_string())))
    }

    fn visit_borrowed_str<E>(self, value: &'de str) -> Result<Self::Value, E> {
        Ok(UniqueValue(Value::String(value.to_string())))
    }

    fn visit_string<E>(self, value: String) -> Result<Self::Value, E> {
        Ok(UniqueValue(Value::String(value)))
    }

    fn visit_none<E>(self) -> Result<Self::Value, E> {
        Ok(UniqueValue(Value::Null))
    }

    fn visit_unit<E>(self) -> Result<Self::Value, E> {
        Ok(UniqueValue(Value::Null))
    }

    fn visit_some<D>(self, deserializer: D) -> Result<Self::Value, D::Error>
    where
        D: Deserializer<'de>,
    {
        UniqueValue::deserialize(deserializer)
    }

    fn visit_seq<A>(self, mut sequence: A) -> Result<Self::Value, A::Error>
    where
        A: SeqAccess<'de>,
    {
        let mut values = Vec::new();
        while let Some(UniqueValue(value)) = sequence.next_element()? {
            values.push(value);
        }
        Ok(UniqueValue(Value::Array(values)))
    }

    fn visit_map<A>(self, mut map: A) -> Result<Self::Value, A::Error>
    where
        A: MapAccess<'de>,
    {
        let mut values = Map::new();
        while let Some(key) = map.next_key::<String>()? {
            if values.contains_key(&key) {
                return Err(de::Error::custom(format!("duplicate JSON key {key:?}")));
            }
            let UniqueValue(value) = map.next_value()?;
            values.insert(key, value);
        }
        Ok(UniqueValue(Value::Object(values)))
    }
}

pub(crate) fn decode(
    signal: &str,
    content_type: &str,
    body: &[u8],
) -> Result<(&'static str, Payload), String> {
    if content_type == "application/json" {
        let UniqueValue(value) =
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
