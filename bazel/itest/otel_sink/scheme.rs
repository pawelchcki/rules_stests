use alloc::format;
use alloc::string::String;
use alloc::vec;
use alloc::vec::Vec;
use core::convert::Infallible;
use stak_device::Device;
use stak_file::VoidFileSystem;
use stak_process_context::VoidProcessContext;
use stak_r7rs::SmallPrimitiveSet;
use stak_time::VoidClock;
use stak_vm::{Cons, Error, Memory, Profiler, Value, Vm};

const COMPILER_BYTECODE: &[u8] = include_bytes!(env!("STAK_COMPILER_BYTECODE"));
const PRELUDE: &[u8] = include_bytes!(env!("STAK_PRELUDE"));
const COMPILER_HEAP_CELLS: usize = 1 << 22;
const VALIDATOR_HEAP_CELLS: usize = 1 << 20;
const VM_CALL_BUDGET: usize = 50_000_000;

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
}

impl Device for MemoryDevice<'_> {
    type Error = Infallible;

    fn read(&mut self) -> Result<Option<u8>, Self::Error> {
        let byte = self.input.get(self.input_index).copied();
        self.input_index += usize::from(byte.is_some());
        Ok(byte)
    }

    fn write(&mut self, byte: u8) -> Result<(), Self::Error> {
        self.output.push(byte);
        Ok(())
    }

    fn write_error(&mut self, byte: u8) -> Result<(), Self::Error> {
        self.error.push(byte);
        Ok(())
    }
}

pub fn evaluate(source: &[u8], input: &[u8]) -> Result<(Vec<u8>, usize), String> {
    let (bytecode, compilation_calls) = compile(source)?;
    let (output, validation_calls) = run(&bytecode, input, "validation", VALIDATOR_HEAP_CELLS)?;
    Ok((output, compilation_calls + validation_calls))
}

fn compile(source: &[u8]) -> Result<(Vec<u8>, usize), String> {
    let mut input = Vec::with_capacity(PRELUDE.len() + source.len() + 1);
    input.extend_from_slice(PRELUDE);
    input.push(b'\n');
    input.extend_from_slice(source);
    run(
        COMPILER_BYTECODE,
        &input,
        "compilation",
        COMPILER_HEAP_CELLS,
    )
}

fn run(
    bytecode: &[u8],
    input: &[u8],
    phase: &str,
    heap_cells: usize,
) -> Result<(Vec<u8>, usize), String> {
    let mut output = Vec::new();
    let mut error_output = Vec::new();
    let mut budget = CallBudget {
        remaining: VM_CALL_BUDGET,
        exhausted: false,
    };
    let result = {
        let device = MemoryDevice {
            input,
            input_index: 0,
            output: &mut output,
            error: &mut error_output,
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
        .map_err(|error| format!("Stak {phase} VM initialization failed: {error}"))?
        .with_profiler(&mut budget);
        vm.run(bytecode.iter().copied())
    };

    if budget.exhausted {
        return Err(format!(
            "Stak {phase} exceeded the {VM_CALL_BUDGET}-call sandbox budget"
        ));
    }
    if let Err(error) = result {
        let detail = String::from_utf8_lossy(&error_output);
        let partial = String::from_utf8_lossy(&output);
        return Err(if detail.is_empty() {
            format!("Stak {phase} failed: {error}; stdout: {}", partial.trim())
        } else {
            format!(
                "Stak {phase} failed: {error}: {}; stdout: {}",
                detail.trim(),
                partial.trim()
            )
        });
    }
    if !error_output.is_empty() {
        return Err(format!(
            "Stak {phase} wrote to stderr: {}",
            String::from_utf8_lossy(&error_output).trim()
        ));
    }
    Ok((output, VM_CALL_BUDGET - budget.remaining))
}
