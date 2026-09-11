use crate::data::Record;
use alloc::format;
use alloc::string::String;
use alloc::vec::Vec;
use core::ffi::CStr;
use rustix::fd::OwnedFd;
use rustix::fs::{Mode, OFlags};

pub(crate) fn persist(output: &CStr, records: &[Record]) -> Result<(), String> {
    persist_parts(output, None, records)
}

pub(crate) fn persist_parts(
    output: &CStr,
    frozen: Option<&[Record]>,
    live: &[Record],
) -> Result<(), String> {
    let records = frozen.into_iter().flatten().chain(live).collect::<Vec<_>>();
    let mut bytes = serde_json::to_vec_pretty(&records)
        .map_err(|error| format!("serialize output JSON: {error}"))?;
    bytes.push(b'\n');
    persist_bytes(output, &bytes)
}

pub(crate) fn persist_bytes(output: &CStr, bytes: &[u8]) -> Result<(), String> {
    let file = rustix::fs::open(
        output,
        OFlags::CREATE | OFlags::TRUNC | OFlags::WRONLY,
        Mode::RUSR | Mode::WUSR | Mode::RGRP | Mode::ROTH,
    )
    .map_err(|error| format!("open output file: {error}"))?;
    write_all(&file, bytes).map_err(|error| format!("write output file: {error}"))
}

fn write_all(fd: &OwnedFd, mut bytes: &[u8]) -> Result<(), rustix::io::Errno> {
    while !bytes.is_empty() {
        let count = rustix::io::write(fd, bytes)?;
        bytes = &bytes[count..];
    }
    Ok(())
}

pub(crate) fn read_bytes(path: &CStr) -> Result<Vec<u8>, String> {
    let file = rustix::fs::open(path, OFlags::RDONLY, Mode::empty())
        .map_err(|error| format!("open input: {error}"))?;
    let mut bytes = Vec::new();
    let mut buffer = [0u8; 8192];
    loop {
        let count =
            rustix::io::read(&file, &mut buffer).map_err(|error| format!("read input: {error}"))?;
        if count == 0 {
            return Ok(bytes);
        }
        if bytes.len() + count > 4 * 1024 * 1024 {
            return Err("compiler source exceeds limit".into());
        }
        bytes.extend_from_slice(&buffer[..count]);
    }
}

// Maintain a complete JSON array on disk with O(new record) serialization.
// dump/reset still materialize the full, frozen capture for review artifacts.
pub(crate) fn append_record(output: &CStr, record: &Record) -> Result<(), String> {
    let bytes =
        serde_json::to_vec_pretty(record).map_err(|error| format!("serialize record: {error}"))?;
    let file = rustix::fs::open(
        output,
        OFlags::CREATE | OFlags::RDWR,
        Mode::RUSR | Mode::WUSR | Mode::RGRP | Mode::ROTH,
    )
    .map_err(|error| format!("open capture: {error}"))?;
    let length = rustix::fs::seek(&file, rustix::fs::SeekFrom::End(0))
        .map_err(|error| format!("seek capture: {error}"))?;
    if length == 0 {
        write_all(&file, b"[").map_err(|error| format!("write capture: {error}"))?;
    } else {
        rustix::fs::seek(&file, rustix::fs::SeekFrom::End(-2))
            .map_err(|error| format!("seek capture: {error}"))?;
        if length > 3 {
            write_all(&file, b",").map_err(|error| format!("write capture: {error}"))?;
        }
    }
    write_all(&file, &bytes)
        .and_then(|_| write_all(&file, b"]\n"))
        .map_err(|error| format!("append capture: {error}"))
}
