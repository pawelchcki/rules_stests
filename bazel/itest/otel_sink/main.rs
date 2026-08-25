#![no_std]
#![no_main]

extern crate alloc;

mod proto;

use alloc::ffi::CString;
use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec::Vec;
use core::arch::global_asm;
use core::ffi::{c_char, CStr};
use core::panic::PanicInfo;
use prost::Message;
use rustix::fd::OwnedFd;
use rustix::fs::{Mode, OFlags};
use rustix::net::{
    acceptfrom, bind, listen, socket, AddressFamily, Ipv4Addr, SocketAddrAny,
    SocketAddrV4, SocketType,
};
use rustix::time::{clock_gettime, ClockId};
use serde::Serialize;
use serde_json::Value;

const MAX_REQUEST_BYTES: usize = 16 * 1024 * 1024;

#[global_allocator]
static ALLOCATOR: emballoc::Allocator<67108864> = emballoc::Allocator::new();

global_asm!(
    r#"
    .global _start
    .type _start,@function
_start:
    mov rdi, rsp
    and rsp, -16
    call rust_start
    ud2
"#
);

#[derive(Serialize)]
struct Header {
    name: String,
    value: String,
}

#[derive(Serialize)]
struct RequestMetadata {
    method: String,
    path: String,
    http_version: String,
    headers: Vec<Header>,
    content_type: String,
    content_encoding: String,
    content_length: usize,
    decoded_length: usize,
}

#[derive(Serialize)]
struct Record {
    received_unix_nano: u64,
    remote_address: String,
    request: RequestMetadata,
    signal: String,
    encoding: String,
    payload: Value,
}

struct Request {
    method: String,
    path: String,
    http_version: String,
    headers: Vec<Header>,
    body: Vec<u8>,
}

impl Request {
    fn header(&self, wanted: &str) -> Option<&str> {
        self.headers
            .iter()
            .find(|header| header.name.eq_ignore_ascii_case(wanted))
            .map(|header| header.value.as_str())
    }
}

#[unsafe(no_mangle)]
unsafe extern "C" fn rust_start(stack: *const usize) -> ! {
    let argc = unsafe { *stack };
    let argv = unsafe { core::slice::from_raw_parts(stack.add(1), argc) };
    let mut port = 4318u16;
    let mut output = CString::new("otel-sink.json").unwrap();
    let mut index = 1usize;
    while index < argv.len() {
        let argument = unsafe { CStr::from_ptr(argv[index] as *const c_char) }.to_bytes();
        if argument == b"--port" && index + 1 < argv.len() {
            let value = unsafe { CStr::from_ptr(argv[index + 1] as *const c_char) }.to_bytes();
            port = parse_port(value).unwrap_or_else(|| die(b"invalid --port\n"));
            index += 2;
        } else if argument == b"--output" && index + 1 < argv.len() {
            let value = unsafe { CStr::from_ptr(argv[index + 1] as *const c_char) }.to_bytes();
            output = CString::new(value).unwrap_or_else(|_| die(b"invalid --output\n"));
            index += 2;
        } else {
            die(b"usage: otel_sink [--port PORT] [--output FILE]\n");
        }
    }

    if let Err(error) = serve(port, output.as_c_str()) {
        write_stderr(b"otel_sink: ");
        write_stderr(error.as_bytes());
        write_stderr(b"\n");
        rustix::runtime::exit_group(1)
    }
    rustix::runtime::exit_group(0)
}

fn parse_port(bytes: &[u8]) -> Option<u16> {
    let mut value = 0u16;
    if bytes.is_empty() {
        return None;
    }
    for byte in bytes {
        if !byte.is_ascii_digit() {
            return None;
        }
        value = value.checked_mul(10)?.checked_add((byte - b'0') as u16)?;
    }
    (value != 0).then_some(value)
}

fn serve(port: u16, output: &CStr) -> Result<(), String> {
    let listener = socket(AddressFamily::INET, SocketType::STREAM, None)
        .map_err(|error| format!("socket: {error}"))?;
    bind(
        &listener,
        &SocketAddrV4::new(Ipv4Addr::UNSPECIFIED, port),
    )
    .map_err(|error| format!("bind port {port}: {error}"))?;
    listen(&listener, 128).map_err(|error| format!("listen: {error}"))?;

    let mut records = Vec::<Record>::new();
    persist(output, &records)?;
    let startup = format!(
        "otel_sink: listening on 0.0.0.0:{port}; pretty JSON output: {}\n",
        String::from_utf8_lossy(output.to_bytes())
    );
    write_stdout(startup.as_bytes());

    loop {
        let (connection, remote) = acceptfrom(&listener).map_err(|error| format!("accept: {error}"))?;
        handle_connection(&connection, remote.as_ref(), output, &mut records);
    }
}

fn handle_connection(
    connection: &OwnedFd,
    remote: Option<&SocketAddrAny>,
    output: &CStr,
    records: &mut Vec<Record>,
) {
    let request = match read_request(connection) {
        Ok(request) => request,
        Err(error) => {
            respond(connection, 400, "text/plain", error.as_bytes());
            return;
        }
    };

    if request.method == "GET" && request.path == "/healthz" {
        respond(connection, 200, "application/json", b"{\"status\":\"ok\"}\n");
        return;
    }
    if request.method == "GET" && request.path == "/dump" {
        match serde_json::to_vec_pretty(records) {
            Ok(mut bytes) => {
                bytes.push(b'\n');
                respond(connection, 200, "application/json", &bytes);
            }
            Err(error) => respond(connection, 500, "text/plain", error.to_string().as_bytes()),
        }
        return;
    }
    if request.method != "POST" {
        respond(connection, 405, "text/plain", b"expected POST\n");
        return;
    }

    let signal = match request.path.as_str() {
        "/v1/traces" => "traces",
        "/v1/metrics" => "metrics",
        "/v1/logs" => "logs",
        _ => {
            respond(connection, 404, "text/plain", b"unknown OTLP endpoint\n");
            return;
        }
    };
    let content_encoding = request.header("content-encoding").unwrap_or("identity").to_string();
    if content_encoding != "identity" && !content_encoding.is_empty() {
        respond(connection, 415, "text/plain", b"only identity content encoding is supported\n");
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
    let (encoding, payload) = match decode(signal, &content_type, &request.body) {
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
    if let Err(error) = persist(output, records) {
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

fn decode(signal: &str, content_type: &str, body: &[u8]) -> Result<(&'static str, Value), String> {
    if content_type == "application/json" {
        return serde_json::from_slice(body)
            .map(|value| ("json", value))
            .map_err(|error| format!("invalid OTLP JSON: {error}"));
    }
    if content_type != "application/x-protobuf" && content_type != "application/protobuf" {
        return Err(format!("unsupported content type {content_type:?}"));
    }
    let value = match signal {
        "traces" => serde_json::to_value(
            proto::ExportTraceServiceRequest::decode(body)
                .map_err(|error| format!("invalid trace protobuf: {error}"))?,
        ),
        "metrics" => serde_json::to_value(
            proto::ExportMetricsServiceRequest::decode(body)
                .map_err(|error| format!("invalid metrics protobuf: {error}"))?,
        ),
        "logs" => serde_json::to_value(
            proto::ExportLogsServiceRequest::decode(body)
                .map_err(|error| format!("invalid logs protobuf: {error}"))?,
        ),
        _ => unreachable!(),
    }
    .map_err(|error| format!("serialize decoded protobuf: {error}"))?;
    Ok(("protobuf", value))
}

fn read_request(connection: &OwnedFd) -> Result<Request, String> {
    let mut bytes = Vec::with_capacity(8192);
    let header_end;
    loop {
        if let Some(position) = find(&bytes, b"\r\n\r\n") {
            header_end = position + 4;
            break;
        }
        if bytes.len() >= MAX_REQUEST_BYTES {
            return Err("request headers exceed limit".to_string());
        }
        let mut chunk = [0u8; 8192];
        let count = rustix::io::read(connection, &mut chunk)
            .map_err(|error| format!("read request: {error}"))?;
        if count == 0 {
            return Err("connection closed before headers completed".to_string());
        }
        bytes.extend_from_slice(&chunk[..count]);
    }

    let head = core::str::from_utf8(&bytes[..header_end - 4])
        .map_err(|_| "request headers are not UTF-8".to_string())?;
    let mut lines = head.split("\r\n");
    let mut request_line = lines
        .next()
        .ok_or_else(|| "missing HTTP request line".to_string())?
        .split_whitespace();
    let method = request_line.next().unwrap_or("").to_string();
    let path = request_line.next().unwrap_or("").to_string();
    let http_version = request_line.next().unwrap_or("").to_string();
    if method.is_empty() || path.is_empty() || http_version != "HTTP/1.1" {
        return Err("invalid HTTP/1.1 request line".to_string());
    }
    let mut headers = Vec::new();
    for line in lines {
        let (name, value) = line
            .split_once(':')
            .ok_or_else(|| "malformed HTTP header".to_string())?;
        headers.push(Header {
            name: name.trim().to_ascii_lowercase(),
            value: value.trim().to_string(),
        });
    }
    if headers.iter().any(|header| {
        header.name == "transfer-encoding" && !header.value.eq_ignore_ascii_case("identity")
    }) {
        return Err("chunked transfer encoding is not supported".to_string());
    }
    let content_length = headers
        .iter()
        .find(|header| header.name == "content-length")
        .map(|header| header.value.parse::<usize>())
        .transpose()
        .map_err(|_| "invalid Content-Length".to_string())?
        .unwrap_or(0);
    if content_length > MAX_REQUEST_BYTES || header_end + content_length > MAX_REQUEST_BYTES {
        return Err("request body exceeds limit".to_string());
    }
    while bytes.len() < header_end + content_length {
        let mut chunk = [0u8; 8192];
        let count = rustix::io::read(connection, &mut chunk)
            .map_err(|error| format!("read request body: {error}"))?;
        if count == 0 {
            return Err("connection closed before request body completed".to_string());
        }
        bytes.extend_from_slice(&chunk[..count]);
        if bytes.len() > MAX_REQUEST_BYTES {
            return Err("request body exceeds limit".to_string());
        }
    }
    Ok(Request {
        method,
        path,
        http_version,
        headers,
        body: bytes[header_end..header_end + content_length].to_vec(),
    })
}

fn find(haystack: &[u8], needle: &[u8]) -> Option<usize> {
    haystack
        .windows(needle.len())
        .position(|window| window == needle)
}

fn persist(output: &CStr, records: &[Record]) -> Result<(), String> {
    let mut bytes = serde_json::to_vec_pretty(records)
        .map_err(|error| format!("serialize output JSON: {error}"))?;
    bytes.push(b'\n');
    let file = rustix::fs::open(
        output,
        OFlags::CREATE | OFlags::TRUNC | OFlags::WRONLY,
        Mode::RUSR | Mode::WUSR | Mode::RGRP | Mode::ROTH,
    )
    .map_err(|error| format!("open output file: {error}"))?;
    write_all(&file, &bytes).map_err(|error| format!("write output file: {error}"))
}

fn respond(connection: &OwnedFd, status: u16, content_type: &str, body: &[u8]) {
    let reason = match status {
        200 => "OK",
        400 => "Bad Request",
        404 => "Not Found",
        405 => "Method Not Allowed",
        415 => "Unsupported Media Type",
        _ => "Internal Server Error",
    };
    let head = format!(
        "HTTP/1.1 {status} {reason}\r\nContent-Type: {content_type}\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
        body.len()
    );
    let _ = write_all(connection, head.as_bytes());
    let _ = write_all(connection, body);
}

fn write_all(fd: &OwnedFd, mut bytes: &[u8]) -> Result<(), rustix::io::Errno> {
    while !bytes.is_empty() {
        let count = rustix::io::write(fd, bytes)?;
        bytes = &bytes[count..];
    }
    Ok(())
}

fn write_stdout(bytes: &[u8]) {
    let _ = rustix::io::write(unsafe { rustix::stdio::stdout() }, bytes);
}

fn write_stderr(bytes: &[u8]) {
    let _ = rustix::io::write(unsafe { rustix::stdio::stderr() }, bytes);
}

fn die(message: &[u8]) -> ! {
    write_stderr(message);
    rustix::runtime::exit_group(2)
}

#[panic_handler]
fn panic(info: &PanicInfo<'_>) -> ! {
    write_stderr(b"otel_sink panic: ");
    struct PanicWriter;
    impl core::fmt::Write for PanicWriter {
        fn write_str(&mut self, text: &str) -> core::fmt::Result {
            write_stderr(text.as_bytes());
            Ok(())
        }
    }
    let _ = core::fmt::write(&mut PanicWriter, format_args!("{info}\n"));
    rustix::runtime::exit_group(101)
}

// `alloc` and LLVM lower bulk memory operations to these C ABI symbols even
// though this executable deliberately does not link libc.
#[unsafe(no_mangle)]
unsafe extern "C" fn memcpy(destination: *mut u8, source: *const u8, count: usize) -> *mut u8 {
    for index in 0..count {
        let byte = unsafe { core::ptr::read_volatile(source.add(index)) };
        unsafe { core::ptr::write_volatile(destination.add(index), byte) };
    }
    destination
}

#[unsafe(no_mangle)]
unsafe extern "C" fn memmove(destination: *mut u8, source: *const u8, count: usize) -> *mut u8 {
    if (destination as usize) <= (source as usize) {
        for index in 0..count {
            let byte = unsafe { core::ptr::read_volatile(source.add(index)) };
            unsafe { core::ptr::write_volatile(destination.add(index), byte) };
        }
    } else {
        for index in (0..count).rev() {
            let byte = unsafe { core::ptr::read_volatile(source.add(index)) };
            unsafe { core::ptr::write_volatile(destination.add(index), byte) };
        }
    }
    destination
}

#[unsafe(no_mangle)]
unsafe extern "C" fn memset(destination: *mut u8, value: i32, count: usize) -> *mut u8 {
    for index in 0..count {
        unsafe { core::ptr::write_volatile(destination.add(index), value as u8) };
    }
    destination
}

#[unsafe(no_mangle)]
unsafe extern "C" fn memcmp(left: *const u8, right: *const u8, count: usize) -> i32 {
    for index in 0..count {
        let left_byte = unsafe { core::ptr::read_volatile(left.add(index)) };
        let right_byte = unsafe { core::ptr::read_volatile(right.add(index)) };
        if left_byte != right_byte {
            return left_byte as i32 - right_byte as i32;
        }
    }
    0
}

#[unsafe(no_mangle)]
unsafe extern "C" fn bcmp(left: *const u8, right: *const u8, count: usize) -> i32 {
    unsafe { memcmp(left, right, count) }
}

#[unsafe(no_mangle)]
unsafe extern "C" fn strlen(mut value: *const u8) -> usize {
    let start = value;
    while unsafe { core::ptr::read_volatile(value) } != 0 {
        value = unsafe { value.add(1) };
    }
    unsafe { value.offset_from(start) as usize }
}

#[unsafe(no_mangle)]
extern "C" fn rust_eh_personality() {}

#[unsafe(no_mangle)]
unsafe extern "C" fn _Unwind_Resume() -> ! {
    rustix::runtime::exit_group(102)
}
