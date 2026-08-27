use alloc::format;
use alloc::string::String;
use alloc::vec;
use alloc::vec::Vec;
use stak_device::{BufferError, Device};
use stak_file::VoidFileSystem;
use stak_process_context::VoidProcessContext;
use stak_r7rs::SmallPrimitiveSet;
use stak_time::VoidClock;
use stak_vm::{Cons, Error, Memory, Profiler, Value, Vm};

const COMPILER_BYTECODE: &[u8] = include_bytes!(env!("STAK_COMPILER_BYTECODE"));
const PRELUDE: &[u8] = include_bytes!(env!("STAK_PRELUDE"));
const COMPILER_HEAP_CELLS: usize = 1 << 22;
// The driver's startup reset clears traces but not metrics or logs, so a
// capture grows with the test's wall-clock duration: the Python exporter emits
// another metric batch every OTEL_METRIC_EXPORT_INTERVAL. A heavily parallel
// run therefore validates a substantially larger capture than a quiet one, and
// 1 << 20 cells exhausted the heap under a full 90-test CI run.
const VALIDATOR_HEAP_CELLS: usize = 1 << 22;
const COMPILER_CALL_BUDGET: usize = 100_000_000;
const VALIDATOR_CALL_BUDGET: usize = 50_000_000;
const VM_OUTPUT_BUDGET: usize = 1 << 20;
pub const CONTRACT_ASSERTION_MARKER: &str = "OTLP contract assertion:";
const CONTRACT_FRAME_PREFIX: &[u8] = b"[[OTLP-CONTRACT-V1:";
const CONTRACT_FRAME_SEPARATOR: &[u8] = b"]]";
const CONTRACT_FRAME_SUFFIX: &[u8] = b"OTLP contract sentinel";

pub(crate) enum EvaluationFailure {
    Contract(String),
    Fault(String),
}

struct CallBudget {
    remaining: usize,
    exhausted: bool,
}

impl<H> Profiler<H> for CallBudget {
    fn profile_call(
        &mut self,
        _memory: &Memory<H>,
        _call_code: Cons,
        _return: bool,
    ) -> Result<(), Error> {
        if self.remaining == 0 {
            self.exhausted = true;
            return Err(Error::OutOfMemory);
        }
        self.remaining -= 1;
        Ok(())
    }

    fn profile_return(&mut self, _memory: &Memory<H>) -> Result<(), Error> {
        Ok(())
    }

    fn profile_event(&mut self, _name: &str) -> Result<(), Error> {
        Ok(())
    }
}

struct MemoryDevice<'a> {
    input: &'a [u8],
    input_index: usize,
    output: &'a mut Vec<u8>,
    error: &'a mut Vec<u8>,
    output_exhausted: &'a mut bool,
    error_exhausted: &'a mut bool,
}

impl Device for MemoryDevice<'_> {
    type Error = BufferError;

    fn read(&mut self) -> Result<Option<u8>, Self::Error> {
        let byte = self.input.get(self.input_index).copied();
        self.input_index += usize::from(byte.is_some());
        Ok(byte)
    }

    fn write(&mut self, byte: u8) -> Result<(), Self::Error> {
        if self.output.len() >= VM_OUTPUT_BUDGET {
            *self.output_exhausted = true;
            return Err(BufferError::Write);
        }
        self.output.push(byte);
        Ok(())
    }

    fn write_error(&mut self, byte: u8) -> Result<(), Self::Error> {
        if self.error.len() >= VM_OUTPUT_BUDGET {
            *self.error_exhausted = true;
            return Err(BufferError::Write);
        }
        self.error.push(byte);
        Ok(())
    }
}

pub fn evaluate(
    source: &[u8],
    input: &[u8],
) -> Result<(Vec<u8>, usize), (EvaluationFailure, usize)> {
    let (bytecode, compilation_calls) = compile(source)?;
    match run(
        &bytecode,
        input,
        "validation",
        VALIDATOR_HEAP_CELLS,
        VALIDATOR_CALL_BUDGET,
    ) {
        Ok((output, validation_calls)) => Ok((output, compilation_calls + validation_calls)),
        Err((error, validation_calls)) => Err((error, compilation_calls + validation_calls)),
    }
}

fn compile(source: &[u8]) -> Result<(Vec<u8>, usize), (EvaluationFailure, usize)> {
    let mut input = Vec::with_capacity(PRELUDE.len() + source.len() + 1);
    input.extend_from_slice(PRELUDE);
    input.push(b'\n');
    input.extend_from_slice(source);
    run(
        COMPILER_BYTECODE,
        &input,
        "compilation",
        COMPILER_HEAP_CELLS,
        COMPILER_CALL_BUDGET,
    )
}

fn run(
    bytecode: &[u8],
    input: &[u8],
    phase: &str,
    heap_cells: usize,
    call_budget: usize,
) -> Result<(Vec<u8>, usize), (EvaluationFailure, usize)> {
    let mut output = Vec::new();
    let mut error_output = Vec::new();
    let mut output_exhausted = false;
    let mut error_exhausted = false;
    let mut budget = CallBudget {
        remaining: call_budget,
        exhausted: false,
    };
    let result = {
        let device = MemoryDevice {
            input,
            input_index: 0,
            output: &mut output,
            error: &mut error_output,
            output_exhausted: &mut output_exhausted,
            error_exhausted: &mut error_exhausted,
        };
        let heap = vec![Value::default(); heap_cells];
        let mut vm = Vm::new(
            heap,
            SmallPrimitiveSet::new(
                device,
                VoidFileSystem::new(),
                VoidProcessContext::new(),
                VoidClock::new(),
            ),
        )
        .map_err(|error| {
            (
                EvaluationFailure::Fault(format!("Stak {phase} VM initialization failed: {error}")),
                0,
            )
        })?
        .with_profiler(&mut budget);
        vm.run(bytecode.iter().copied())
    };
    let calls = call_budget - budget.remaining;

    if budget.exhausted {
        return Err((
            EvaluationFailure::Fault(format!(
                "Stak {phase} exceeded the {call_budget}-call sandbox budget"
            )),
            calls,
        ));
    }
    if output_exhausted || error_exhausted {
        return Err((
            EvaluationFailure::Fault(format!(
                "Stak {phase} exceeded the {VM_OUTPUT_BUDGET}-byte output sandbox limit"
            )),
            calls,
        ));
    }
    if let Err(error) = result {
        let detail = String::from_utf8_lossy(&error_output);
        let partial = String::from_utf8_lossy(&output);
        let message = if detail.is_empty() {
            format!("Stak {phase} failed: {error}; stdout: {}", partial.trim())
        } else {
            format!(
                "Stak {phase} failed: {error}: {}; stdout: {}",
                detail.trim(),
                partial.trim()
            )
        };
        let failure = if phase == "validation" {
            contract_message(&error_output)
                .map(EvaluationFailure::Contract)
                .unwrap_or(EvaluationFailure::Fault(message))
        } else {
            EvaluationFailure::Fault(message)
        };
        return Err((failure, calls));
    }
    if !error_output.is_empty() {
        return Err((
            EvaluationFailure::Fault(format!(
                "Stak {phase} wrote to stderr: {}",
                String::from_utf8_lossy(&error_output).trim()
            )),
            calls,
        ));
    }
    Ok((output, calls))
}

fn contract_message(error_output: &[u8]) -> Option<String> {
    let framed = error_output.strip_prefix(CONTRACT_FRAME_PREFIX)?;
    let separator = framed
        .windows(CONTRACT_FRAME_SEPARATOR.len())
        .position(|window| window == CONTRACT_FRAME_SEPARATOR)?;
    let length = core::str::from_utf8(&framed[..separator])
        .ok()?
        .parse::<usize>()
        .ok()?;
    let payload = &framed[separator + CONTRACT_FRAME_SEPARATOR.len()..];
    let payload_text = core::str::from_utf8(payload).ok()?;
    let message_end = payload_text
        .char_indices()
        .map(|(index, _)| index)
        .nth(length)
        .unwrap_or(payload.len());
    if payload_text[..message_end].chars().count() != length {
        return None;
    }
    let (message, remainder) = payload.split_at(message_end);
    let trailing = remainder.strip_prefix(CONTRACT_FRAME_SUFFIX)?;
    if !trailing.iter().all(u8::is_ascii_whitespace) {
        return None;
    }
    Some(format!(
        "{CONTRACT_ASSERTION_MARKER} {}",
        core::str::from_utf8(message).ok()?
    ))
}
