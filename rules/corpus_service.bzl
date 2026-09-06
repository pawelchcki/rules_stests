"""Common service interface for corpora backed by materialized app directories."""

load("@rules_itest//:itest.bzl", "itest_service")

_LAUNCHER = Label("//harness:app_launcher")

def corpus_service(
        name,
        rootfs,
        runtime,
        instance,
        command,
        args = [],
        injection = None,
        data = [],
        **kwargs):
    """Launches an app as a rules_itest service within the Bazel test action.

    Extraction is a separate build action. This macro consumes an already
    materialized directory, whether produced by oci_rootfs or another rule.

    Args:
        name: Name of the itest_service target.
        rootfs: Label of the materialized app directory (consumer-relative).
        runtime: "python", "ruby" or "native" for the bundled runtime adapter.
        instance: Lowercase letters, digits, hyphens and underscores; identifies
            writable state under TEST_TMPDIR/rules_stests/<instance>/state.
        command: Python/Rails command, or rootfs-relative native binary.
        args: App arguments, including rules_itest substitutions such as $${PORT}.
        injection: Optional struct with rootfs and flags, as returned by
            otel_injection, python_auto_injection or ruby_auto_injection.
        data: Additional service runfiles.
        **kwargs: itest_service options, including env, deps, health checks,
            port assignment and shutdown timeout. exe is owned by this macro.
    """
    if runtime not in ["python", "ruby", "native"]:
        fail("runtime must be python, ruby or native")
    if not instance or [c for c in instance.elems() if c not in "abcdefghijklmnopqrstuvwxyz0123456789-_"]:
        fail("instance must contain only lowercase letters, digits, hyphens and underscores")
    if not command:
        fail("command must be non-empty")
    if "exe" in kwargs:
        fail("corpus_service owns exe; select the runtime and command instead")

    launcher_args = [
        "--runtime=" + runtime,
        "--instance=" + instance,
        "--rootfs=$(rlocationpath {})".format(rootfs),
    ]
    launcher_data = data + [rootfs]
    if injection:
        launcher_args.extend(injection.flags)
        launcher_data.append(injection.rootfs)
    itest_service(
        name = name,
        exe = _LAUNCHER,
        args = launcher_args + ["--", command] + args,
        data = launcher_data,
        **kwargs
    )
