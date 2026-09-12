use crate::data::{Payload, Record};
use crate::otlp;
use alloc::vec::Vec;
use rustix::fs::{Mode, OFlags};
use serde::Serialize;

#[derive(Serialize)]
pub(crate) struct Stats {
    capture_overflow: bool,
    records: usize,
    trace_requests: usize,
    trace_spans: usize,
    metric_requests: usize,
    log_requests: usize,
    validation_runs: usize,
    validation_failures: usize,
    validation_last_duration_ms: u64,
    validation_last_compilation_ms: u64,
    validation_last_calls: usize,
    peak_rss_kib: Option<usize>,
}

#[derive(Default)]
pub(crate) struct ValidationStats {
    pub(crate) runs: usize,
    pub(crate) failures: usize,
    pub(crate) last_duration_ms: u64,
    pub(crate) last_compilation_ms: u64,
    pub(crate) last_calls: usize,
    pub(crate) capture: CaptureCounters,
}

#[derive(Default)]
pub(crate) struct CaptureCounters {
    pub(crate) overflow: bool,
    pub(crate) records: usize,
    pub(crate) retained_bytes: usize,
    trace_requests: usize,
    trace_spans: usize,
    metric_requests: usize,
    log_requests: usize,
}

impl CaptureCounters {
    pub(crate) fn add(&mut self, record: &Record) {
        self.records += 1;
        self.retained_bytes += record.retained_bytes;
        match record.signal.as_str() {
            "traces" => {
                self.trace_requests += 1;
                self.trace_spans += match &record.payload {
                    Payload::Traces(payload) => payload
                        .resource_spans
                        .iter()
                        .flat_map(|resource| &resource.scope_spans)
                        .map(|scope| scope.spans.len())
                        .sum(),
                    Payload::Json(payload) if payload.get("wire_version").is_some() => {
                        crate::datadog::span_count(record)
                    }
                    Payload::Json(payload) => otlp::json_trace_span_count(payload),
                    _ => 0,
                };
            }
            "metrics" => self.metric_requests += 1,
            "logs" => self.log_requests += 1,
            _ => {}
        }
    }
}

pub(crate) fn snapshot(validation: &ValidationStats) -> Stats {
    let capture = &validation.capture;
    Stats {
        capture_overflow: capture.overflow,
        records: capture.records,
        trace_requests: capture.trace_requests,
        trace_spans: capture.trace_spans,
        metric_requests: capture.metric_requests,
        log_requests: capture.log_requests,
        validation_runs: validation.runs,
        validation_failures: validation.failures,
        validation_last_duration_ms: validation.last_duration_ms,
        validation_last_compilation_ms: validation.last_compilation_ms,
        validation_last_calls: validation.last_calls,
        peak_rss_kib: process_peak_rss_kib(),
    }
}

pub(crate) fn elapsed_millis(start: rustix::time::Timespec, end: rustix::time::Timespec) -> u64 {
    let nanos = (end.tv_sec as i128 - start.tv_sec as i128) * 1_000_000_000 + end.tv_nsec as i128
        - start.tv_nsec as i128;
    (nanos.max(0) / 1_000_000) as u64
}

fn process_peak_rss_kib() -> Option<usize> {
    let file = rustix::fs::open(c"/proc/self/status", OFlags::RDONLY, Mode::empty()).ok()?;
    let mut contents = Vec::with_capacity(2048);
    let mut chunk = [0u8; 2048];
    loop {
        let count = rustix::io::read(&file, &mut chunk).ok()?;
        if count == 0 {
            break;
        }
        contents.extend_from_slice(&chunk[..count]);
    }
    let text = core::str::from_utf8(&contents).ok()?;
    let line = text.lines().find(|line| line.starts_with("VmHWM:"))?;
    line.split_whitespace().nth(1)?.parse().ok()
}
