use crate::data::{Record, RequestMetadata};
use crate::http::{read_request, respond, valid_token};
use crate::platform::write_stdout;
use crate::stats::{self, ValidationStats};
use crate::{datadog, otlp, scheme, storage, validation};
use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec::Vec;
use core::ffi::CStr;
use core::time::Duration;
use rustix::fd::OwnedFd;
use rustix::net::sockopt::{Timeout, set_socket_reuseport, set_socket_timeout};
use rustix::net::{
    AddressFamily, Ipv4Addr, SocketAddrAny, SocketAddrV4, SocketType, acceptfrom, bind, listen,
    socket,
};
use rustix::time::{ClockId, clock_gettime};

const MAX_CAPTURE_REQUEST_BYTES: usize = 4 * 1024 * 1024;
const MAX_CAPTURE_RECORDS: usize = 4096;
const MAX_DECODED_OTLP_BYTES: usize = 1024 * 1024;

pub(crate) fn serve(port: u16, output: &CStr, stress_capture: bool) -> Result<(), String> {
    let listener = socket(AddressFamily::INET, SocketType::STREAM, None)
        .map_err(|error| format!("socket: {error}"))?;
    set_socket_reuseport(&listener, true).map_err(|error| format!("SO_REUSEPORT: {error}"))?;
    bind(&listener, &SocketAddrV4::new(Ipv4Addr::UNSPECIFIED, port))
        .map_err(|error| format!("bind port {port}: {error}"))?;
    listen(&listener, 128).map_err(|error| format!("listen: {error}"))?;

    let mut records = Vec::<Record>::new();
    let mut frozen_records = None::<Vec<Record>>;
    let mut validation_stats = ValidationStats::default();
    let mut dd_records = Vec::<Record>::new();
    let mut dd_frozen_records = None::<Vec<Record>>;
    let mut dd_validation_stats = ValidationStats::default();
    storage::persist(output, &records)?;
    let startup = format!(
        "telemetry_sink: listening on 0.0.0.0:{port}; pretty JSON output: {}\n",
        String::from_utf8_lossy(output.to_bytes())
    );
    write_stdout(startup.as_bytes());

    loop {
        let (connection, remote) =
            acceptfrom(&listener).map_err(|error| format!("accept: {error}"))?;
        if let Err(error) =
            set_socket_timeout(&connection, Timeout::Send, Some(Duration::from_secs(2)))
        {
            write_stdout(format!("telemetry_sink: set send timeout: {error}\n").as_bytes());
            continue;
        }
        if let Err(error) =
            set_socket_timeout(&connection, Timeout::Recv, Some(Duration::from_secs(2)))
        {
            respond(
                &connection,
                500,
                "text/plain",
                format!("set receive timeout: {error}\n").as_bytes(),
            );
            continue;
        }
        handle_connection(
            &connection,
            remote.as_ref(),
            output,
            &mut records,
            &mut frozen_records,
            &mut validation_stats,
            &mut dd_records,
            &mut dd_frozen_records,
            &mut dd_validation_stats,
            if stress_capture {
                64 * 1024 * 1024
            } else {
                MAX_CAPTURE_REQUEST_BYTES
            },
        );
    }
}

fn handle_connection(
    connection: &OwnedFd,
    remote: Option<&SocketAddrAny>,
    output: &CStr,
    records: &mut Vec<Record>,
    frozen_records: &mut Option<Vec<Record>>,
    validation_stats: &mut ValidationStats,
    dd_records: &mut Vec<Record>,
    dd_frozen_records: &mut Option<Vec<Record>>,
    dd_validation_stats: &mut ValidationStats,
    capture_limit: usize,
) {
    let mut request = match read_request(
        connection,
        if capture_limit > MAX_CAPTURE_REQUEST_BYTES {
            8 * 1024 * 1024
        } else {
            1024 * 1024
        },
    ) {
        Ok(request) => request,
        Err(error) => {
            if error.status() == 413 && capture_limit > MAX_CAPTURE_REQUEST_BYTES {
                dd_validation_stats.capture.overflow = true;
            }
            respond(
                connection,
                error.status(),
                "text/plain",
                error.message().as_bytes(),
            );
            return;
        }
    };

    let original_path = request.path.clone();
    let (path, query) = original_path
        .split_once('?')
        .unwrap_or((&original_path, ""));
    let query_value = |name: &str| {
        query
            .split('&')
            .filter_map(|p| p.split_once('='))
            .find(|(key, _)| *key == name)
            .map(|(_, value)| value)
    };
    let protocol = query_value("protocol").unwrap_or("otlp");
    if protocol != "otlp" && protocol != "datadog" {
        respond(
            connection,
            400,
            "text/plain",
            b"unknown telemetry protocol\n",
        );
        return;
    }
    let dd_intake = matches!(path, "/v0.4/traces" | "/v0.5/traces");
    let otlp_intake = matches!(path, "/v1/traces" | "/v1/metrics" | "/v1/logs");
    if query_value("protocol").is_some()
        && ((dd_intake && protocol != "datadog") || (otlp_intake && protocol != "otlp"))
    {
        respond(
            connection,
            400,
            "text/plain",
            b"intake protocol does not match endpoint\n",
        );
        return;
    }
    let is_dd = dd_intake || (!otlp_intake && protocol == "datadog");
    let (records, frozen_records, validation_stats) = if is_dd {
        (dd_records, dd_frozen_records, dd_validation_stats)
    } else {
        (records, frozen_records, validation_stats)
    };
    let dd_output = alloc::ffi::CString::new(format!(
        "{}.datadog.json",
        String::from_utf8_lossy(output.to_bytes())
    ))
    .unwrap();
    let output = if is_dd { dd_output.as_c_str() } else { output };
    request.path = path.to_string();
    if request.method == "GET" && path == "/info" {
        respond(connection, 200, "application/json", b"{\"endpoints\":[\"/v0.4/traces\",\"/v0.5/traces\"],\"client_drop_p0s\":false,\"span_events\":false}\n");
        return;
    }
    if request.method == "GET" && request.path == "/healthz" {
        respond(
            connection,
            200,
            "application/json",
            b"{\"status\":\"ok\"}\n",
        );
        return;
    }
    if request.method == "GET" && request.path == "/dump" {
        let snapshot = freeze_records(records, frozen_records);
        match serde_json::to_vec_pretty(snapshot) {
            Ok(mut bytes) => {
                bytes.push(b'\n');
                match storage::persist_bytes(output, &bytes) {
                    Ok(()) => respond(connection, 200, "application/json", &bytes),
                    Err(error) => respond(connection, 500, "text/plain", error.as_bytes()),
                }
            }
            Err(error) => respond(connection, 500, "text/plain", error.to_string().as_bytes()),
        }
        return;
    }
    if request.method == "GET" && request.path == "/dump.scm" {
        let snapshot = freeze_records(records, frozen_records);
        match if is_dd {
            datadog::capture_to_scheme(snapshot)
        } else {
            validation::capture_to_scheme(snapshot)
        } {
            Ok(input) => respond(connection, 200, "text/x-scheme", &input),
            Err(error) => respond(connection, 500, "text/plain", error.as_bytes()),
        }
        return;
    }
    if request.method == "GET" && request.path == "/stats" {
        match serde_json::to_vec(&stats::snapshot(validation_stats)) {
            Ok(mut bytes) => {
                bytes.push(b'\n');
                respond(connection, 200, "application/json", &bytes);
            }
            Err(error) => respond(connection, 500, "text/plain", error.to_string().as_bytes()),
        }
        return;
    }
    if request.method == "POST"
        && matches!(
            request.path.as_str(),
            "/reset" | "/reset/traces" | "/reset/traces-and-metrics"
        )
    {
        if request.path == "/reset" {
            records.clear();
            *frozen_records = None;
        } else {
            let retain = |record: &Record| {
                record.signal != "traces"
                    && (request.path != "/reset/traces-and-metrics" || record.signal != "metrics")
            };
            records.retain(&retain);
            if let Some(snapshot) = frozen_records {
                snapshot.retain(retain);
            }
        }
        *validation_stats = ValidationStats::default();
        for record in frozen_records.iter().flatten().chain(records.iter()) {
            validation_stats.capture.add(record);
        }
        match storage::persist_parts(output, frozen_records.as_deref(), records) {
            Ok(()) => respond(connection, 200, "application/json", b"{}\n"),
            Err(error) => respond(connection, 500, "text/plain", error.as_bytes()),
        }
        return;
    }
    if request.method == "GET" && path == "/candidate" {
        let app = query_value("app").unwrap_or("");
        let scenario = query_value("scenario").unwrap_or("");
        let snapshot = frozen_records.as_deref().unwrap_or(records);
        match if is_dd {
            datadog::candidate(snapshot, app, scenario)
        } else {
            validation::scenario_shape_candidate(snapshot, app)
        } {
            Ok(candidate) => respond(connection, 200, "text/x-scheme", &candidate),
            Err(error) => respond(connection, 422, "text/plain", error.as_bytes()),
        }
        return;
    }
    if request.method == "POST"
        && matches!(request.path.as_str(), "/validate" | "/validate-bytecode")
    {
        let snapshot = frozen_records.as_deref().unwrap_or(records);
        validate(
            connection,
            &request.body,
            snapshot,
            validation_stats,
            is_dd,
            request.path == "/validate-bytecode",
            query_value("app").unwrap_or(""),
            query_value("scenario").unwrap_or(""),
        );
        return;
    }
    if request.method != "POST" && !(is_dd && request.method == "PUT") {
        respond(connection, 405, "text/plain", b"expected POST\n");
        return;
    }

    ingest(
        connection,
        remote,
        output,
        request,
        records,
        &mut validation_stats.capture,
        capture_limit,
    );
}

fn freeze_records<'a>(live: &mut Vec<Record>, frozen: &'a mut Option<Vec<Record>>) -> &'a [Record] {
    let snapshot = frozen.get_or_insert_with(Vec::new);
    snapshot.append(live);
    snapshot
}

fn validate(
    connection: &OwnedFd,
    source: &[u8],
    records: &[Record],
    validation_stats: &mut ValidationStats,
    is_dd: bool,
    bytecode: bool,
    app: &str,
    scenario: &str,
) {
    let started = clock_gettime(ClockId::Monotonic);
    validation_stats.last_compilation_ms = 0;
    let input = match if is_dd {
        datadog::capture_to_scheme_with_context(records, app, scenario)
    } else {
        validation::capture_to_scheme(records)
    } {
        Ok(input) => input,
        Err(error) => {
            let finished = clock_gettime(ClockId::Monotonic);
            validation_stats.runs += 1;
            validation_stats.failures += 1;
            validation_stats.last_duration_ms = stats::elapsed_millis(started, finished);
            validation_stats.last_calls = 0;
            let message = format!(
                "{} contract assertion: {error}",
                if is_dd { "Datadog" } else { "OTLP" }
            );
            respond(connection, 409, "text/plain", message.as_bytes());
            return;
        }
    };
    let result = if bytecode {
        scheme::evaluate_bytecode(source, &input)
    } else {
        scheme::evaluate_timed(source, &input, &mut validation_stats.last_compilation_ms)
    };
    let finished = clock_gettime(ClockId::Monotonic);
    validation_stats.runs += 1;
    validation_stats.last_duration_ms = stats::elapsed_millis(started, finished);
    match result {
        Ok((output, calls)) => {
            validation_stats.last_calls = calls;
            respond(connection, 200, "text/plain", &output);
        }
        Err((error, calls)) => {
            validation_stats.failures += 1;
            validation_stats.last_calls = calls;
            let (status, message) = match error {
                scheme::EvaluationFailure::Contract(message) => (409, message),
                scheme::EvaluationFailure::Fault(message) => (422, message),
            };
            respond(connection, status, "text/plain", message.as_bytes());
        }
    }
}

fn ingest(
    connection: &OwnedFd,
    remote: Option<&SocketAddrAny>,
    output: &CStr,
    request: crate::http::Request,
    records: &mut Vec<Record>,
    counters: &mut stats::CaptureCounters,
    capture_limit: usize,
) {
    let signal = match request.path.as_str() {
        "/v1/traces" | "/v0.4/traces" | "/v0.5/traces" => "traces",
        "/v1/metrics" => "metrics",
        "/v1/logs" => "logs",
        _ => {
            respond(connection, 404, "text/plain", b"unknown OTLP endpoint\n");
            return;
        }
    };
    let is_dd = request.path.starts_with("/v0.");
    let content_encoding_count = request
        .headers
        .iter()
        .filter(|header| header.name.eq_ignore_ascii_case("content-encoding"))
        .count();
    if content_encoding_count > 1 {
        respond(
            connection,
            400,
            "text/plain",
            b"Content-Encoding header must be unique\n",
        );
        return;
    }
    let content_encoding = request
        .header("content-encoding")
        .unwrap_or("identity")
        .to_ascii_lowercase();
    if !content_encoding.eq_ignore_ascii_case("identity") && !content_encoding.is_empty() {
        respond(
            connection,
            415,
            "text/plain",
            b"only identity content encoding is supported\n",
        );
        return;
    }
    let content_type = match parse_content_type(
        request
            .header("content-type")
            .unwrap_or("application/x-protobuf"),
    ) {
        Ok(content_type) => content_type,
        Err(error) => {
            respond(connection, 400, "text/plain", error.as_bytes());
            return;
        }
    };
    if content_type != "application/json"
        && content_type != "application/x-protobuf"
        && content_type != "application/protobuf"
        && !(is_dd && content_type == "application/msgpack")
    {
        respond(
            connection,
            415,
            "text/plain",
            format!("unsupported content type {content_type:?}\n").as_bytes(),
        );
        return;
    }
    if is_dd
        && !matches!(
            content_type.as_str(),
            "application/msgpack" | "application/json"
        )
    {
        respond(
            connection,
            415,
            "text/plain",
            b"unsupported Datadog content type\n",
        );
        return;
    }
    let retained_count = counters.records;
    let retained_bytes = Some(counters.retained_bytes);
    if retained_count >= MAX_CAPTURE_RECORDS
        || retained_bytes
            .and_then(|total| total.checked_add(request.body.len()))
            .is_none_or(|total| total > capture_limit)
    {
        counters.overflow = true;
        respond(
            connection,
            413,
            "text/plain",
            if is_dd {
                b"cumulative Datadog capture exceeds limit\n"
            } else {
                b"cumulative OTLP capture exceeds limit\n"
            },
        );
        return;
    }
    let (encoding, payload) = match if is_dd {
        datadog::decode(
            &request.path,
            &content_type,
            &request.body,
            if capture_limit > MAX_CAPTURE_REQUEST_BYTES {
                8 * 1024 * 1024
            } else {
                1024 * 1024
            },
        )
        .map(|p| {
            (
                if content_type == "application/json" {
                    "json"
                } else {
                    "msgpack"
                },
                p,
            )
        })
    } else {
        otlp::decode(signal, &content_type, &request.body)
    } {
        Ok(decoded) => decoded,
        Err(error) => {
            if error.contains("limit") || error.contains("budget") {
                counters.overflow = true;
            }
            respond(connection, 400, "text/plain", error.as_bytes());
            return;
        }
    };
    let decoded_size = match serde_json::to_vec(&payload) {
        Ok(encoded) => encoded.len(),
        Err(error) => {
            respond(
                connection,
                400,
                "text/plain",
                format!("serialize decoded OTLP payload: {error}").as_bytes(),
            );
            return;
        }
    };
    if decoded_size
        > if is_dd && capture_limit > MAX_CAPTURE_REQUEST_BYTES {
            8 * 1024 * 1024
        } else {
            MAX_DECODED_OTLP_BYTES
        }
    {
        counters.overflow = true;
        respond(
            connection,
            413,
            "text/plain",
            b"decoded OTLP payload exceeds limit\n",
        );
        return;
    }
    let received = clock_gettime(ClockId::Realtime);
    let received_unix_nano = received.tv_sec as u64 * 1_000_000_000 + received.tv_nsec as u64;
    let remote_address = remote
        .map(|address| format!("{address:?}"))
        .unwrap_or_else(|| "unknown".to_string());
    let content_length = request.body.len();
    let retained_bytes = match estimated_retained_bytes(
        &request,
        &remote_address,
        signal,
        &encoding,
        &content_type,
        &content_encoding,
        decoded_size,
    ) {
        Some(size) => size,
        None => {
            respond(
                connection,
                413,
                "text/plain",
                b"cumulative OTLP capture exceeds limit\n",
            );
            return;
        }
    };
    if counters
        .retained_bytes
        .checked_add(retained_bytes)
        .is_none_or(|total| total > capture_limit)
    {
        counters.overflow = true;
        respond(
            connection,
            413,
            "text/plain",
            if is_dd {
                b"cumulative Datadog capture exceeds limit\n"
            } else {
                b"cumulative OTLP capture exceeds limit\n"
            },
        );
        return;
    }
    records.push(Record {
        received_unix_nano,
        remote_address,
        request: RequestMetadata {
            method: request.method,
            path: request.path,
            http_version: request.http_version,
            headers: request.headers,
            content_type: content_type.clone(),
            content_encoding,
            content_length,
            decoded_length: content_length,
        },
        signal: signal.to_string(),
        encoding: encoding.to_string(),
        payload,
        retained_bytes,
    });
    if let Err(error) = storage::append_record(output, records.last().unwrap()) {
        records.pop();
        respond(connection, 500, "text/plain", error.as_bytes());
        return;
    }
    counters.add(records.last().unwrap());
    if is_dd {
        respond(
            connection,
            200,
            "application/json",
            b"{\"rate_by_service\":{}}\n",
        );
    } else if encoding == "json" {
        respond(connection, 200, "application/json", b"{}\n");
    } else {
        respond(connection, 200, "application/x-protobuf", b"");
    }
}

fn estimated_retained_bytes(
    request: &crate::http::Request,
    remote_address: &str,
    signal: &str,
    encoding: &str,
    content_type: &str,
    content_encoding: &str,
    decoded_size: usize,
) -> Option<usize> {
    // The decoded protobuf structs / JSON DOM retain allocations beyond their
    // serialized bytes. A factor of two is a conservative bound for this sink,
    // and the remaining terms account for every retained metadata string.
    let payload = decoded_size.checked_mul(2)?;
    let headers = request.headers.iter().try_fold(0usize, |total, header| {
        total
            .checked_add(header.name.len())?
            .checked_add(header.value.len())
    })?;
    [
        payload,
        request.body.len(),
        headers,
        remote_address.len(),
        request.method.len(),
        request.path.len(),
        request.http_version.len(),
        signal.len(),
        encoding.len(),
        content_type.len(),
        content_encoding.len(),
        core::mem::size_of::<Record>(),
    ]
    .into_iter()
    .try_fold(0usize, usize::checked_add)
}

fn parse_content_type(value: &str) -> Result<String, String> {
    let parts = split_content_type(value)?;
    let media_type = parts.first().copied().unwrap_or("").trim();
    let (type_name, subtype) = media_type
        .split_once('/')
        .ok_or_else(|| "malformed Content-Type media type".to_string())?;
    if !valid_token(type_name) || !valid_token(subtype) {
        return Err("malformed Content-Type media type".to_string());
    }
    for parameter in parts.iter().skip(1) {
        let (name, parameter_value) = parameter
            .trim()
            .split_once('=')
            .ok_or_else(|| "malformed Content-Type parameter".to_string())?;
        if !valid_token(name.trim()) || !valid_parameter_value(parameter_value.trim()) {
            return Err("malformed Content-Type parameter".to_string());
        }
    }
    Ok(media_type.to_ascii_lowercase())
}

fn split_content_type(value: &str) -> Result<Vec<&str>, String> {
    let mut parts = Vec::new();
    let mut start = 0;
    let mut quoted = false;
    let mut escaped = false;
    for (index, byte) in value.bytes().enumerate() {
        if escaped {
            escaped = false;
            continue;
        }
        match byte {
            b'\\' if quoted => escaped = true,
            b'"' => quoted = !quoted,
            b';' if !quoted => {
                parts.push(&value[start..index]);
                start = index + 1;
            }
            _ => {}
        }
    }
    if quoted || escaped {
        return Err("malformed Content-Type parameter".to_string());
    }
    parts.push(&value[start..]);
    Ok(parts)
}

fn valid_parameter_value(value: &str) -> bool {
    if valid_token(value) {
        return true;
    }
    let bytes = value.as_bytes();
    if bytes.len() < 2 || bytes[0] != b'"' || bytes[bytes.len() - 1] != b'"' {
        return false;
    }
    let mut index = 1;
    while index < bytes.len() - 1 {
        let byte = bytes[index];
        if byte == b'\\' {
            index += 1;
            if index >= bytes.len() - 1 {
                return false;
            }
            let escaped = bytes[index];
            if escaped != b'\t' && !(0x20..=0x7e).contains(&escaped) {
                return false;
            }
        } else if byte == b'"' || (byte != b'\t' && !(0x20..=0x7e).contains(&byte)) {
            return false;
        }
        index += 1;
    }
    true
}
