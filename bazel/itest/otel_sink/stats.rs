use crate::data::{Payload, Record};
use crate::otlp;
use alloc::vec::Vec;
use rustix::fs::{Mode, OFlags};
use serde::Serialize;

#[derive(Serialize)]
pub(crate) struct Stats {
    records: usize,
    trace_requests: usize,
    trace_spans: usize,
    metric_requests: usize,
    log_requests: usize,
    validation_runs: usize,
    validation_failures: usize,
    validation_last_duration_ms: u64,
    validation_last_calls: usize,
    peak_rss_kib: Option<usize>,
}

#[derive(Default)]
pub(crate) struct ValidationStats {
    pub(crate) runs: usize,
    pub(crate) failures: usize,
    pub(crate) last_duration_ms: u64,
    pub(crate) last_calls: usize,
}

pub(crate) fn snapshot(records: &[Record], validation: &ValidationStats) -> Stats {
    let mut result = Stats {
        records: records.len(),
        trace_requests: 0,
        trace_spans: 0,
        metric_requests: 0,
        log_requests: 0,
        validation_runs: validation.runs,
        validation_failures: validation.failures,
        validation_last_duration_ms: validation.last_duration_ms,
        validation_last_calls: validation.last_calls,
        peak_rss_kib: process_peak_rss_kib(),
    };
    for record in records {
        match record.signal.as_str() {
            "traces" => {
                result.trace_requests += 1;
                result.trace_spans += match &record.payload {
                    Payload::Traces(payload) => payload
                        .resource_spans
                        .iter()
                        .flat_map(|resource| &resource.scope_spans)
                        .map(|scope| scope.spans.len())
                        .sum(),
                    Payload::Json(payload) => otlp::json_trace_span_count(payload),
                    _ => 0,
                };
            }
            "metrics" => result.metric_requests += 1,
            "logs" => result.log_requests += 1,
            _ => {}
        }
    }
    result
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
