pub(crate) fn write_stdout(bytes: &[u8]) {
    let _ = rustix::io::write(unsafe { rustix::stdio::stdout() }, bytes);
}

pub(crate) fn write_stderr(bytes: &[u8]) {
    let _ = rustix::io::write(unsafe { rustix::stdio::stderr() }, bytes);
}
