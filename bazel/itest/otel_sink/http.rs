use crate::data::Header;
use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec::Vec;
use rustix::fd::OwnedFd;
use rustix::net::{SendFlags, send};

const MAX_REQUEST_BYTES: usize = 16 * 1024 * 1024;
const MAX_VALIDATION_SOURCE_BYTES: usize = 256 * 1024;

pub(crate) struct Request {
    pub(crate) method: String,
    pub(crate) path: String,
    pub(crate) http_version: String,
    pub(crate) headers: Vec<Header>,
    pub(crate) body: Vec<u8>,
}

impl Request {
    pub(crate) fn header(&self, wanted: &str) -> Option<&str> {
        self.headers
            .iter()
            .find(|header| header.name.eq_ignore_ascii_case(wanted))
            .map(|header| header.value.as_str())
    }
}

pub(crate) fn read_request(connection: &OwnedFd) -> Result<Request, String> {
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
    let max_body_bytes = if method == "POST" && path == "/validate" {
        MAX_VALIDATION_SOURCE_BYTES
    } else {
        MAX_REQUEST_BYTES
    };
    if content_length > max_body_bytes {
        return Err(if max_body_bytes == MAX_VALIDATION_SOURCE_BYTES {
            "Scheme validation source exceeds limit".to_string()
        } else {
            "request body exceeds limit".to_string()
        });
    }
    let request_end = header_end
        .checked_add(content_length)
        .ok_or_else(|| "request body exceeds limit".to_string())?;
    if request_end > MAX_REQUEST_BYTES {
        return Err("request body exceeds limit".to_string());
    }
    while bytes.len() < request_end {
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
        body: bytes[header_end..request_end].to_vec(),
    })
}

pub(crate) fn respond(connection: &OwnedFd, status: u16, content_type: &str, body: &[u8]) {
    let reason = match status {
        200 => "OK",
        400 => "Bad Request",
        404 => "Not Found",
        405 => "Method Not Allowed",
        409 => "Conflict",
        415 => "Unsupported Media Type",
        422 => "Unprocessable Content",
        _ => "Internal Server Error",
    };
    let head = format!(
        "HTTP/1.1 {status} {reason}\r\nContent-Type: {content_type}\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
        body.len()
    );
    let _ = send_all(connection, head.as_bytes());
    let _ = send_all(connection, body);
}

fn find(haystack: &[u8], needle: &[u8]) -> Option<usize> {
    haystack
        .windows(needle.len())
        .position(|window| window == needle)
}

fn send_all(fd: &OwnedFd, mut bytes: &[u8]) -> Result<(), rustix::io::Errno> {
    while !bytes.is_empty() {
        let count = send(fd, bytes, SendFlags::NOSIGNAL)?;
        bytes = &bytes[count..];
    }
    Ok(())
}
