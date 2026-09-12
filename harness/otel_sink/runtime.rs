use crate::platform::write_stderr;
use crate::server;
use alloc::ffi::CString;
use core::arch::{asm, global_asm};
use core::ffi::{CStr, c_char};
use core::panic::PanicInfo;

// Native dictionary expansion creates many small strings and map nodes. A
// segregated allocator avoids a full-heap scan for every allocation/free while
// retaining the sink's original fixed 64 MiB memory ceiling.
static mut HEAP: [core::mem::MaybeUninit<u8>; 536870912] =
    [core::mem::MaybeUninit::uninit(); 536870912];
#[global_allocator]
static ALLOCATOR: talc::Talck<spin::Mutex<()>, talc::ErrOnOom> =
    talc::Talc::new(talc::ErrOnOom).lock();

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

#[unsafe(no_mangle)]
unsafe extern "C" fn rust_start(stack: *const usize) -> ! {
    let argc = unsafe { *stack };
    let argv = unsafe { core::slice::from_raw_parts(stack.add(1), argc) };
    let stress_capture = argv.iter().skip(1).any(|arg| {
        unsafe { CStr::from_ptr(*arg as *const c_char) }.to_bytes() == b"--stress-capture"
    });
    let heap_bytes = if stress_capture {
        512 * 1024 * 1024
    } else {
        64 * 1024 * 1024
    };
    // Claim the larger bounded arena only for explicitly requested stress runs.
    let base = (&raw mut HEAP).cast::<u8>();
    if unsafe {
        ALLOCATOR
            .lock()
            .claim(talc::Span::new(base, base.add(heap_bytes)))
    }
    .is_err()
    {
        die(b"unable to initialize telemetry sink heap\n");
    }
    let mut port = 4318u16;
    let mut output = CString::new("otel-sink.json").unwrap();
    let mut compile_source = None;
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
        } else if argument == b"--stress-capture" {
            index += 1;
        } else if argument == b"--compile" && index + 1 < argv.len() {
            let value = unsafe { CStr::from_ptr(argv[index + 1] as *const c_char) }.to_bytes();
            compile_source =
                Some(CString::new(value).unwrap_or_else(|_| die(b"invalid --compile\n")));
            index += 2;
        } else {
            die(b"usage: telemetry_sink [--port PORT] [--output FILE]\n");
        }
    }

    if let Some(path) = compile_source {
        let source =
            crate::storage::read_bytes(&path).unwrap_or_else(|error| die(error.as_bytes()));
        match crate::scheme::compile(&source) {
            Ok((bytecode, _)) => crate::storage::persist_bytes(&output, &bytecode)
                .unwrap_or_else(|error| die(error.as_bytes())),
            Err((
                crate::scheme::EvaluationFailure::Contract(error)
                | crate::scheme::EvaluationFailure::Fault(error),
                _,
            )) => die(error.as_bytes()),
        }
        rustix::runtime::exit_group(0)
    }

    if let Err(error) = server::serve(port, output.as_c_str(), stress_capture) {
        write_stderr(b"telemetry_sink: ");
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

fn die(message: &[u8]) -> ! {
    write_stderr(message);
    rustix::runtime::exit_group(2)
}

#[panic_handler]
fn panic(info: &PanicInfo<'_>) -> ! {
    write_stderr(b"telemetry_sink panic: ");
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
    unsafe {
        asm!(
            "rep movsb",
            inout("rdi") destination => _,
            inout("rsi") source => _,
            inout("rcx") count => _,
            options(nostack, preserves_flags),
        );
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
    unsafe {
        asm!(
            "rep stosb",
            inout("rdi") destination => _,
            inout("rcx") count => _,
            in("al") value as u8,
            options(nostack, preserves_flags),
        );
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
