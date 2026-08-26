use crate::data::Record;
use alloc::format;
use alloc::string::String;
use core::ffi::CStr;
use rustix::fd::OwnedFd;
use rustix::fs::{Mode, OFlags};

pub(crate) fn persist(output: &CStr, records: &[Record]) -> Result<(), String> {
    let mut bytes = serde_json::to_vec_pretty(records)
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
