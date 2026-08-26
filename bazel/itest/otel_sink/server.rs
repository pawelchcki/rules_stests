use crate::data::{Record, RequestMetadata};
use crate::http::{read_request, respond};
use crate::platform::write_stdout;
use crate::stats::{self, ValidationStats};
use crate::{otlp, scheme, storage, validation};
use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec::Vec;
use core::ffi::CStr;
use rustix::fd::OwnedFd;
use rustix::net::sockopt::set_socket_reuseport;
use rustix::net::{
    AddressFamily, Ipv4Addr, SocketAddrAny, SocketAddrV4, SocketType, acceptfrom, bind, listen,
    socket,
};
use rustix::time::{ClockId, clock_gettime};

pub(crate) fn serve(port: u16, output: &CStr) -> Result<(), String> {
    let listener = socket(AddressFamily::INET, SocketType::STREAM, None)
        .map_err(|error| format!("socket: {error}"))?;
    set_socket_reuseport(&listener, true).map_err(|error| format!("SO_REUSEPORT: {error}"))?;
    bind(&listener, &SocketAddrV4::new(Ipv4Addr::UNSPECIFIED, port))
        .map_err(|error| format!("bind port {port}: {error}"))?;
    listen(&listener, 128).map_err(|error| format!("listen: {error}"))?;

    let mut records = Vec::<Record>::new();
    let mut validation_stats = ValidationStats::default();
    storage::persist(output, &records)?;
    let startup = format!(
        "otel_sink: listening on 0.0.0.0:{port}; pretty JSON output: {}\n",
        String::from_utf8_lossy(output.to_bytes())
    );
    write_stdout(startup.as_bytes());

    loop {
        let (connection, remote) =
            acceptfrom(&listener).map_err(|error| format!("accept: {error}"))?;
        handle_connection(
            &connection,
            remote.as_ref(),
            output,
            &mut records,
            &mut validation_stats,
        );
    }
}

fn handle_connection(
    connection: &OwnedFd,
    remote: Option<&SocketAddrAny>,
    output: &CStr,
    records: &mut Vec<Record>,
    validation_stats: &mut ValidationStats,
) {
    let request = match read_request(connection) {
        Ok(request) => request,
        Err(error) => {
            respond(connection, 400, "text/plain", error.as_bytes());
            return;
        }
    };

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
        match serde_json::to_vec_pretty(records) {
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
        match validation::capture_to_scheme(records) {
            Ok(input) => respond(connection, 200, "text/x-scheme", &input),
            Err(error) => respond(connection, 500, "text/plain", error.as_bytes()),
        }
        return;
    }
    if request.method == "GET" && request.path == "/stats" {
        match serde_json::to_vec(&stats::snapshot(records, validation_stats)) {
            Ok(mut bytes) => {
                bytes.push(b'\n');
                respond(connection, 200, "application/json", &bytes);
            }
            Err(error) => respond(connection, 500, "text/plain", error.to_string().as_bytes()),
        }
        return;
    }
    if request.method == "POST" && (request.path == "/reset" || request.path == "/reset/traces") {
        if request.path == "/reset" {
            records.clear();
        } else {
            records.retain(|record| record.signal != "traces");
        }
        *validation_stats = ValidationStats::default();
        match storage::persist(output, records) {
            Ok(()) => respond(connection, 200, "application/json", b"{}\n"),
            Err(error) => respond(connection, 500, "text/plain", error.as_bytes()),
        }
        return;
    }
    if request.method == "GET" && request.path.starts_with("/candidate?app=") {
        let app = &request.path["/candidate?app=".len()..];
        match validation::golden_candidate(records, app) {
            Ok(candidate) => respond(connection, 200, "text/x-scheme", &candidate),
            Err(error) => respond(connection, 422, "text/plain", error.as_bytes()),
        }
        return;
    }
    if request.method == "POST" && request.path == "/validate" {
        validate(connection, &request.body, records, validation_stats);
        return;
    }
    if request.method != "POST" {
        respond(connection, 405, "text/plain", b"expected POST\n");
        return;
    }

    ingest(connection, remote, output, request, records);
}

fn validate(
    connection: &OwnedFd,
    source: &[u8],
    records: &[Record],
    validation_stats: &mut ValidationStats,
) {
    let input = match validation::capture_to_scheme(records) {
        Ok(input) => input,
        Err(error) => {
            respond(connection, 500, "text/plain", error.as_bytes());
            return;
        }
    };
    let started = clock_gettime(ClockId::Monotonic);
    let result = scheme::evaluate(source, &input);
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
            let status = if error.contains(scheme::CONTRACT_ASSERTION_MARKER) {
                409
            } else {
                422
            };
            respond(connection, status, "text/plain", error.as_bytes());
        }
    }
}

fn ingest(
    connection: &OwnedFd,
    remote: Option<&SocketAddrAny>,
    output: &CStr,
    request: crate::http::Request,
    records: &mut Vec<Record>,
) {
    let signal = match request.path.as_str() {
        "/v1/traces" => "traces",
        "/v1/metrics" => "metrics",
        "/v1/logs" => "logs",
        _ => {
            respond(connection, 404, "text/plain", b"unknown OTLP endpoint\n");
            return;
        }
    };
    let content_encoding = request
        .header("content-encoding")
        .unwrap_or("identity")
        .to_string();
    if content_encoding != "identity" && !content_encoding.is_empty() {
        respond(
            connection,
            415,
            "text/plain",
            b"only identity content encoding is supported\n",
        );
        return;
    }
    let content_type = request
        .header("content-type")
        .unwrap_or("application/x-protobuf")
        .split(';')
        .next()
        .unwrap_or("")
        .trim()
        .to_ascii_lowercase();
    let (encoding, payload) = match otlp::decode(signal, &content_type, &request.body) {
        Ok(decoded) => decoded,
        Err(error) => {
            respond(connection, 400, "text/plain", error.as_bytes());
            return;
        }
    };
    let received = clock_gettime(ClockId::Realtime);
    let received_unix_nano = received.tv_sec as u64 * 1_000_000_000 + received.tv_nsec as u64;
    let remote_address = remote
        .map(|address| format!("{address:?}"))
        .unwrap_or_else(|| "unknown".to_string());
    let content_length = request.body.len();
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
    });
    if let Err(error) = storage::persist(output, records) {
        records.pop();
        respond(connection, 500, "text/plain", error.as_bytes());
        return;
    }
    if encoding == "json" {
        respond(connection, 200, "application/json", b"{}\n");
    } else {
        respond(connection, 200, "application/x-protobuf", b"");
    }
}
